/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_usb.c

DESCRIPTION
    Application level implementation of USB features

NOTES
    - Conditional on ENABLE_USB define
    - Ensure USB host interface and VM control of USB enabled in project/PS
*/

#include "sink_private.h"
#include "sink_debug.h"
#include "sink_powermanager.h"
#include "sink_usb.h"
#include "sink_usb_descriptors.h"
#include "sink_configmanager.h"
#include "sink_audio.h"
#include "sink_a2dp.h"
#include "sink_avrcp.h"
#include "sink_statemanager.h"
#include "sink_pio.h"
#include "sink_tones.h"
#include "sink_display.h"
#include "sink_audio_routing.h"

#ifdef ENABLE_SUBWOOFER
#include "sink_swat.h"
#endif

#include <usb_device_class.h>
#include <power.h>
#include <panic.h>
#include <print.h>
#include <usb.h>
#include <file.h>
#include <stream.h>
#include <source.h>
#include <boot.h>
#include <string.h>
#include <charger.h>

#ifdef ENABLE_USB
#ifdef ENABLE_USB_AUDIO

#include <csr_a2dp_decoder_common_plugin.h>
#define USB_AUDIO_DISCONNECT_DELAY (500)

static const usb_plugin_info usb_plugins[] =
{
    {SAMPLE_RATE_STEREO, NULL                , usb_plugin_stereo},
    {SAMPLE_RATE_CVC,    &usb_cvc_config     , usb_plugin_mono_nb},
    {SAMPLE_RATE_CVC_WB, &usb_cvc_wb_config  , usb_plugin_mono_wb}
};

#endif /* ENABLE_USB_AUDIO */

#ifdef DEBUG_USB
    #define USB_DEBUG(x) DEBUG(x)
#else
    #define USB_DEBUG(x)
#endif

#define USB_CLASS_ENABLED(x)        ((bool)(theSink.usb.config.device_class & (x)))
#define USB_CLASS_DISABLE(x)        theSink.usb.config.device_class &= ~(x)
#define USB_CLASS_ENABLE(x)         theSink.usb.config.device_class |= (x)

#ifdef HAVE_VBAT_SEL
#define usbDeadBatteryAtBoot()      (ChargerGetBatteryStatusAtBoot() == CHARGER_BATTERY_DEAD)
#else
#define usbDeadBatteryAtBoot()      (TRUE) /* Assume dead battery until initial VBAT reading taken */
#endif
#define usbDeadBatteryProvision()   (theSink.usb.dead_battery && !theSink.usb.enumerated && !theSink.usb.deconfigured)

const char root_name[] = "usb_root";
const char fat_name[]  = "usb_fat";


/*************************************************************************
NAME    
    usbAudioSuspended
    
DESCRIPTION
    Obtains the audio suspend state for USB

RETURNS
    Current audio suspend state
    
**************************************************************************/
usb_audio_suspend_state usbAudioSuspended (void)
{
    USB_DEBUG(("USB: audio suspend_state = %d\n",theSink.usb.audio_suspend_state)); 
    return theSink.usb.audio_suspend_state;
}

/*************************************************************************
NAME    
    usbSetAudioSuspendState
    
DESCRIPTION
    Sets the audio suspend state for USB

RETURNS
    None
    
**************************************************************************/
void usbSetAudioSuspendState (usb_audio_suspend_state state)
{
    if (state == usb_audio_suspend_none)
    {   /* Returning to the unsuspended state */
        theSink.usb.audio_suspend_state = state;
    }
    else
    {   /* Check if we are already suspended before updating state */
        if (theSink.usb.audio_suspend_state == usb_audio_suspend_none)
        {
            theSink.usb.audio_suspend_state = state;
        }
    }
    
    USB_DEBUG(("USB: Setting audio suspend_state = %d\n",theSink.usb.audio_suspend_state)); 
}


/****************************************************************************
NAME
    usbUpdateChargeCurrent

DESCRIPTION
    Set the charge current based on USB state

RETURNS
    void
*/
void usbUpdateChargeCurrent(void)
{
    /* Don't change anything if battery charging disabled */
    if(USB_CLASS_ENABLED(USB_DEVICE_CLASS_TYPE_BATTERY_CHARGING))
        powerManagerUpdateChargeCurrent();
}


/****************************************************************************
NAME
    usbSetLowPowerMode

DESCRIPTION
    If delay is non zero queue a message to reset into low powered mode. If
    delay is zero do nothing.

RETURNS
    void
*/
static void usbSetLowPowerMode(uint8 delay)
{
    /* Only queue low power mode if not enumerated and attached to normal host/hub */
    if(!theSink.usb.enumerated && delay && (UsbAttachedStatus() == HOST_OR_HUB))
    {
        USB_DEBUG(("USB: Queue low power in %d sec\n", delay));
        MessageSendLater(&theSink.task, EventUsrUsbLowPowerMode, 0, D_SEC(delay));
    }
}


/****************************************************************************
NAME
    usbSetBootMode

DESCRIPTION
    Set the boot mode to default or low power

RETURNS
    void
*/
void usbSetBootMode(uint8 bootmode)
{
    /* Don't change anything if battery charging disabled */
    if(!USB_CLASS_ENABLED(USB_DEVICE_CLASS_TYPE_BATTERY_CHARGING))
        return;

    if(BootGetMode() != bootmode)
    {
        USB_DEBUG(("USB: Set Mode %d\n", bootmode));
        BootSetMode(bootmode);
    }
}


/****************************************************************************
NAME
    handleUsbMessage

DESCRIPTION
    Handle firmware USB messages

RETURNS
    void
*/
void handleUsbMessage(Task task, MessageId id, Message message)
{
    USB_DEBUG(("USB: "));
    switch (id)
    {
        case MESSAGE_USB_ATTACHED:
        {
            USB_DEBUG(("MESSAGE_USB_ATTACHED\n"));
            usbUpdateChargeCurrent();
            audioHandleRouting(audio_source_none);
            usbSetLowPowerMode(theSink.usb.config.attach_timeout);
            if(theSink.usb.dead_battery)
                MessageSendLater(&theSink.task, EventSysUsbDeadBatteryTimeout, 0, D_MIN(45));

#if defined(ENABLE_PEER) && defined(ENABLE_USB_AUDIO)
            {
                /*If the USB has disconnected then notify this to the peer device */
                audio_src_conn_state_t  AudioSrcStatus;
                AudioSrcStatus.src = USB_AUDIO;
                AudioSrcStatus.isConnected = TRUE;
                updatePeerAudioConnStatus(AudioSrcStatus);
            }
#endif

            break;
        }
        case MESSAGE_USB_DETACHED:
        {
            USB_DEBUG(("MESSAGE_USB_DETACHED\n"));
            theSink.usb.enumerated = FALSE;
            theSink.usb.suspended  = FALSE;
            theSink.usb.deconfigured = FALSE;
            usbUpdateChargeCurrent();
#ifdef ENABLE_PEER
            PEER_UPDATE_REQUIRED_RELAY_STATE("USB DETACHED");
#endif
            audioHandleRouting(audio_source_none);
            MessageCancelAll(&theSink.task, EventUsrUsbLowPowerMode);
            MessageCancelAll(&theSink.task, EventSysUsbDeadBatteryTimeout);
            break;
        }
        case MESSAGE_USB_ENUMERATED:
        {
            USB_DEBUG(("MESSAGE_USB_ENUMERATED\n"));
            if(!theSink.usb.enumerated)
            {
                theSink.usb.enumerated = TRUE;
                usbUpdateChargeCurrent();
                MessageCancelAll(&theSink.task, EventUsrUsbLowPowerMode);
                MessageCancelAll(&theSink.task, EventSysUsbDeadBatteryTimeout);
            }
            break;
        }
        case MESSAGE_USB_SUSPENDED:
        {
            MessageUsbSuspended* ind = (MessageUsbSuspended*)message;
            USB_DEBUG(("MESSAGE_USB_SUSPENDED - %s\n", (ind->has_suspended ? "Suspend" : "Resume")));
            if(ind->has_suspended != theSink.usb.suspended)
            {
                theSink.usb.suspended = ind->has_suspended;
                usbUpdateChargeCurrent();
            }
            break;
        }
        case MESSAGE_USB_DECONFIGURED:
        {
            USB_DEBUG(("MESSAGE_USB_DECONFIGURED\n"));
            if(theSink.usb.enumerated)
            {
                theSink.usb.enumerated = FALSE;
                theSink.usb.deconfigured  = TRUE;
                usbUpdateChargeCurrent();
                usbSetLowPowerMode(theSink.usb.config.deconfigured_timeout);
            }
            break;
        }
        case MESSAGE_USB_ALT_INTERFACE:
        {
            uint16 interface_id;
            MessageUsbAltInterface* ind = (MessageUsbAltInterface*)message;

            USB_DEBUG(("MESSAGE_USB_ALT_INTERFACE %d %d\n", ind->interface, ind->altsetting));
            UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_MIC_INTERFACE_ID, &interface_id);
            if(interface_id == ind->interface)
            {
                theSink.usb.mic_active = (ind->altsetting ? TRUE : FALSE);
                USB_DEBUG(("USB: Mic ID %d active %d\n", interface_id, theSink.usb.mic_active));
            }
            UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_SPEAKER_INTERFACE_ID, &interface_id);
            if(interface_id == ind->interface)
            {
                theSink.usb.spkr_active = (ind->altsetting ? TRUE : FALSE);
                USB_DEBUG(("USB: Speaker ID %d active %d\n", interface_id, theSink.usb.spkr_active));
                
                if (theSink.usb.spkr_active)
                {
                    usbSetAudioSuspendState(usb_audio_suspend_none);
#ifdef ENABLE_PEER
                    PEER_UPDATE_REQUIRED_RELAY_STATE("USB SPEAKER ACTIVE");
#endif
                }
                else
                {
                    usbSetAudioSuspendState(usb_audio_suspend_remote);
#ifdef ENABLE_PEER
                    PEER_UPDATE_REQUIRED_RELAY_STATE("USB SPEAKER INACTIVE");
#endif
                }
            }
#ifdef ENABLE_USB_AUDIO
            /* check for changes in required audio routing */
            USB_DEBUG(("USB: MESSAGE_USB_ALT_INTERFACE checkAudioRouting\n"));
            MessageCancelFirst(&theSink.task, EventSysCheckAudioRouting);
            MessageSendLater(&theSink.task, EventSysCheckAudioRouting, 0, USB_AUDIO_DISCONNECT_DELAY);
#endif
            break;
        }
        case USB_DEVICE_CLASS_MSG_AUDIO_LEVELS_IND:
        {
            USB_DEBUG(("USB_DEVICE_CLASS_MSG_AUDIO_LEVELS_IND\n"));
            usbAudioSetVolume();
            break;
        }

        /* update of speaker sample rate from usb host */
        case USB_DEVICE_CLASS_MSG_SPEAKER_SAMPLE_RATE_IND:
        {
            USB_DEBUG(("USB_DEVICE_CLASS_MSG_SPEAKER_SAMPLE_RATE_IND: %ld\n",(uint32)((USB_DEVICE_CLASS_SAMPLE_RATE_T *)message)->sample_rate ));
            usbAudioSetSpeakerSampleRate(((USB_DEVICE_CLASS_SAMPLE_RATE_T *)message)->sample_rate);
        }
        break;

        /* update of mic sample rate from usb host */
        case USB_DEVICE_CLASS_MSG_MIC_SAMPLE_RATE_IND:
        {
            USB_DEBUG(("USB_DEVICE_CLASS_MSG_MICR_SAMPLE_RATE_IND: %ld\n",(uint32)((USB_DEVICE_CLASS_SAMPLE_RATE_T *)message)->sample_rate ));
            usbAudioSetMicSampleRate(((USB_DEVICE_CLASS_SAMPLE_RATE_T *)message)->sample_rate);
        }
        break;

        default:
        {
            USB_DEBUG(("Unhandled USB message 0x%x\n", id));
            break;
        }
    }
}


/****************************************************************************
NAME
    usbFileInfo

DESCRIPTION
    Get file info (index and size) for a given file name.

RETURNS
    void
*/
static void usbFileInfo(const char* name, uint8 size_name, usb_file_info* info)
{
    Source source;
    info->index = FileFind(FILE_ROOT, name, size_name);
    source = StreamFileSource(info->index);
    info->size = SourceSize(source);
    SourceClose(source);
}


/****************************************************************************
NAME
    usbFileName

DESCRIPTION
    Get file name from USB root

RETURNS
    void
*/
static void usbFileName(usb_file_info* root, usb_file_name_info* result)
{
    Source source = StreamFileSource(root->index);
    usb_file_name* file = (usb_file_name*)SourceMap(source);

    result->size = 0;

    if(file)
    {
        memmove(result->name, file->name, USB_NAME_SIZE);
        for(result->size = 0; result->size < USB_NAME_SIZE; result->size++)
            if(file->name[result->size] == ' ')
                break;
        *(result->name + result->size) = '.';
        result->size++;
        memmove(result->name + result->size, file->ext, USB_EXT_SIZE);
        result->size += USB_EXT_SIZE;
        SourceClose(source);
    }
#ifdef DEBUG_USB
    {
    uint8 count;
    USB_DEBUG(("USB: File Name "));
    for(count = 0; count < result->size; count++)
        USB_DEBUG(("%c", result->name[count]));
    USB_DEBUG(("\n"));
    }
#endif
}


/****************************************************************************
NAME
    usbTimeCriticalInit

DESCRIPTION
    Initialise USB. This function is time critical and must be called from
    _init. This will fail if either Host Interface is not set to USB or
    VM control of USB is FALSE in PS. It may also fail if Transport in the
    project properties is not set to USB VM.

RETURNS
    void
*/
void usbTimeCriticalInit(void)
{
#ifdef ENABLE_USB_AUDIO
    const usb_plugin_info* plugin;
#endif
    usb_device_class_status status;
    usb_file_info root;
    usb_file_info file;
    usb_file_name_info file_name;

    USB_DEBUG(("USB: Time Critical\n"));

    /* Default to not configured or suspended */
    theSink.usb.ready = FALSE;
    theSink.usb.enumerated = FALSE;
    theSink.usb.suspended  = FALSE;
    theSink.usb.vbus_okay  = TRUE;
    theSink.usb.deconfigured = FALSE;
    theSink.usb.audio_suspend_state = usb_audio_suspend_none;

    /* Check if we booted with dead battery */
    usbSetVbatDead(usbDeadBatteryAtBoot());

    /* Get USB configuration */
    configManagerUsb();

    /* Abort if no device classes supported */
    if(!theSink.usb.config.device_class)
        return;

    usbFileInfo(root_name, sizeof(root_name)-1, &root);
    usbFileName(&root, &file_name);
    usbFileInfo(file_name.name, file_name.size, &file);

    /* If we can't find the help file don't enumerate mass storage */
    if(file.index == FILE_NONE || root.index == FILE_NONE)
        USB_CLASS_DISABLE(USB_DEVICE_CLASS_TYPE_MASS_STORAGE);

#ifdef ENABLE_USB_AUDIO
    plugin = &usb_plugins[theSink.usb.config.plugin_type];
    USB_DEBUG(("USB: Audio Plugin %d\n", theSink.usb.config.plugin_index));

    status = UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_AUDIO_INTERFACE_DESCRIPTORS, 0, 0, (const uint8*)(plugin->usb_descriptors));
    USB_DEBUG(("USB: interface descriptors = %x\n",status));
    /* configure usb audio volume levels/steps */
    status = UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_AUDIO_VOLUMES, 0, 0, (const uint8*)(&usb_stereo_audio_volume_default));
    USB_DEBUG(("USB: volume descriptors = %x\n",status));
#else
    /* If audio not supported don't enumerate as mic or speaker */
    USB_CLASS_DISABLE(USB_DEVICE_CLASS_AUDIO);
#endif

    USB_DEBUG(("USB: Endpoint Setup [0x%04X] - ", theSink.usb.config.device_class));
    /* Attempt to enumerate - abort if failed */
    status = UsbDeviceClassEnumerate(&theSink.task, theSink.usb.config.device_class);

    if(status != usb_device_class_status_success)
    {
        USB_DEBUG(("Error %X\n", status));
        return;
    }

    USB_DEBUG(("Success\n"));
    /* Configure mass storage device */
    if(USB_CLASS_ENABLED(USB_DEVICE_CLASS_TYPE_MASS_STORAGE))
    {
        UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_MASS_STORAGE_FAT_DATA_AREA, file.index, file.size, 0);
        usbFileInfo(fat_name, sizeof(fat_name)-1, &file);
        UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_MASS_STORAGE_FAT_TABLE, file.index, file.size, 0);
        UsbDeviceClassConfigure(USB_DEVICE_CLASS_CONFIG_MASS_STORAGE_FAT_ROOT_DIR, root.index, root.size, 0);
    }
}


/****************************************************************************
NAME
    usbInit

DESCRIPTION
    Initialisation done once the main loop is up and running. Determines USB
    attach status etc.

RETURNS
    void
*/
void usbInit(void)
{
    USB_DEBUG(("USB: Init\n"));

    /* Abort if no device classes supported */
    if(!theSink.usb.config.device_class)
        return;
    /* If battery charging enabled set the charge current */
    usbUpdateChargeCurrent();
#ifdef ENABLE_USB_AUDIO
    /* Pass NULL USB mic Sink until the plugin handles USB mic */
    theSink.a2dp_link_data->a2dp_audio_connect_params.usb_params = NULL;
#endif
    /* Schedule reset to low power mode if attached */
    usbSetLowPowerMode(theSink.usb.config.attach_timeout);
    /* Check for audio */
    theSink.usb.ready = TRUE;
    audioHandleRouting(audio_source_none);
    PioSetPio(theSink.conf1->PIOIO.pio_outputs.PowerOnPIO, pio_drive, TRUE);
}


/****************************************************************************
NAME
    usbSetVbusLevel

DESCRIPTION
    Set whether VBUS is above or below threshold

RETURNS
    void
*/
void usbSetVbusLevel(voltage_reading vbus)
{
    USB_DEBUG(("USB: VBUS %dmV [%d]\n", vbus.voltage, vbus.level));
    theSink.usb.vbus_okay = vbus.level;
}


/****************************************************************************
NAME
    usbSetDeadBattery

DESCRIPTION
    Set whether VBAT is below the dead battery threshold

RETURNS
    void
*/
void usbSetVbatDead(bool dead)
{
    USB_DEBUG(("USB: VBAT %s\n", dead ? "Dead" : "Okay"));
    theSink.usb.dead_battery = dead;
    if(!dead) MessageCancelAll(&theSink.task, EventSysUsbDeadBatteryTimeout);
}


/****************************************************************************
NAME
    usbGetChargeCurrent

DESCRIPTION
    Get USB charger limits

RETURNS
    void
*/
sink_charge_current* usbGetChargeCurrent(void)
{
    /* USB charging not enabled - no limits */
    if(!USB_CLASS_ENABLED(USB_DEVICE_CLASS_TYPE_BATTERY_CHARGING))
        return NULL;

    USB_DEBUG(("USB: Status "));

    /* Set charge current */
    switch(UsbAttachedStatus())
    {
        case HOST_OR_HUB:
            USB_DEBUG(("Host/Hub "));
            if(theSink.usb.suspended)
            {
                USB_DEBUG(("Suspended (Battery %s)\n", usbDeadBatteryProvision() ? "Dead" : "Okay"));
                if(usbDeadBatteryProvision())
                    return &theSink.usb.config.i_susp_db;
                else
                    return &theSink.usb.config.i_susp;
            }
            else if(powerManagerIsChargerFullCurrent())
            {
                USB_DEBUG(("%sEnumerated (Chg Full)\n", theSink.usb.enumerated ? "" : "Not "));
                if(!theSink.usb.enumerated)
                    return &theSink.usb.config.i_att;
                else
                    return &theSink.usb.config.i_conn;
            }
            else
            {
                USB_DEBUG(("%sEnumerated (Chg Partial)\n", theSink.usb.enumerated ? "" : "Not "));
                if(!theSink.usb.enumerated)
                    return &theSink.usb.config.i_att_trickle;
                else
                    return &theSink.usb.config.i_conn_trickle;
            }
#ifdef HAVE_FULL_USB_CHARGER_DETECTION
        case DEDICATED_CHARGER:
            USB_DEBUG(("Dedicated Charger Port%s\n", theSink.usb.vbus_okay ? "" : " Limited"));
            if(theSink.usb.vbus_okay)
                return &theSink.usb.config.i_dchg;
            else
                return &theSink.usb.config.i_lim;

        case HOST_OR_HUB_CHARGER:
        case CHARGING_PORT:
            USB_DEBUG(("Charger Port%s\n", theSink.usb.vbus_okay ? "" : " Limited"));
            if(theSink.usb.vbus_okay)
                return &theSink.usb.config.i_chg;
            else
                return &theSink.usb.config.i_lim;
#endif
        case DETACHED:
        default:
            USB_DEBUG(("Detached\n"));
            if(powerManagerIsChargerConnected())
                return &theSink.usb.config.i_disc;
            else
                return NULL;
    }
}


/****************************************************************************
NAME
    usbIsAttached

DESCRIPTION
    Determine if USB is attached

RETURNS
    TRUE if USB is attached, FALSE otherwise
*/
bool usbIsAttached(void)
{
    /* If not detached return TRUE */
    return (UsbAttachedStatus() != DETACHED);
}


#ifdef ENABLE_USB_AUDIO


/****************************************************************************
NAME
    usbSendHidEvent

DESCRIPTION
    Send HID event over USB

RETURNS
    void
*/
void usbSendHidEvent(usb_device_class_event event)
{
    USB_DEBUG(("USB: HID Event 0x%X\n", event));
    if(USB_CLASS_ENABLED(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL))
        UsbDeviceClassSendEvent(event);
}


/****************************************************************************
NAME
    usbAudioIsAttached

DESCRIPTION
    Determine if USB Audio is attached

RETURNS
    TRUE if USB Audio is attached, FALSE otherwise
*/
bool usbAudioIsAttached(void)
{
    /* If USB detached or not ready - no audio */
    if (!usbIsAttached() || !theSink.usb.ready)
    {
        return FALSE;
    }
    
    /* If USB attached and always on - audio */
    if (theSink.usb.config.audio_always_on)
    {
        return TRUE;
    }
    
    /* If mic and speaker both inactive - no audio */
    if (!theSink.usb.mic_active && !theSink.usb.spkr_active)
    {
        return FALSE;
    }
    
    /* USB speaker can be held active even though we have suspended */
    if (theSink.usb.audio_suspend_state != usb_audio_suspend_none)
    {
        return FALSE;
    }
    
    /* Mic or speaker active - audio */
    return TRUE;
}


/****************************************************************************
NAME
    usbGetVolume

DESCRIPTION
    Extract USB volume setting from USB lib levels

RETURNS
    Volume to pass to csr_usb_audio_plugin
*/
static int16 usbGetVolume(AUDIO_MODE_T* mode)
{
    int16 result;
    bool mic_muted;
    bool spk_muted = FALSE;

    /* Get vol settings from USB lib */
    usb_device_class_audio_levels levels;
    UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_LEVELS, (uint16*)&levels);

    USB_DEBUG(("USB: RAW Gain L %X R %X\n", levels.out_l_vol, levels.out_r_vol));

    /* convert to signed 16 */
    levels.out_l_vol = (int16)(int8)(levels.out_l_vol>>8);
    levels.out_r_vol = (int16)(int8)(levels.out_r_vol>>8);

    USB_DEBUG(("USB: Limited Gain L %X R %X\n", levels.out_l_vol, levels.out_r_vol));
    USB_DEBUG(("USB: Mute M %X S %X\n", levels.in_mute, levels.out_mute));

    if(theSink.usb.config.plugin_type == usb_plugin_stereo)
    {
        /* Pack result */
        result = (theSink.conf1->volume_config.volume_control_config.no_of_steps - ((levels.out_l_vol * theSink.conf1->volume_config.volume_control_config.no_of_steps)/-60));
        /* limit check */
        if(result >= theSink.conf1->volume_config.volume_control_config.no_of_steps)
            result = (theSink.conf1->volume_config.volume_control_config.no_of_steps - 1);
        if(result < 0)
            result = 0;

        /* check for mute state */
        if(levels.out_mute)
        {
            /* set to mute */
            result = VOLUME_A2DP_MUTE_GAIN;    
        }
        
        USB_DEBUG(("USB: Stereo Gain dB %d\n", result));
        displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * result)/theSink.conf1->volume_config.volume_control_config.no_of_steps);
#ifdef ENABLE_SUBWOOFER
        updateSwatVolume(result);
#endif
    }

    else
    {
        /* Use HFP gain mappings */
        /* convert from USB dB to hfp volume steps */
        result = (VOL_NUM_VOL_SETTINGS - ((levels.out_l_vol * VOL_NUM_VOL_SETTINGS)/-60));
        /* limit check */
        if(result >= VOL_NUM_VOL_SETTINGS)
            result = (VOL_NUM_VOL_SETTINGS - 1);
        if(result < 0)
            result = 0;
        /* get table based gain value */
        result = theSink.conf1->volume_config.gVolMaps[ result ].VolGain;

        displayUpdateVolume((VOLUME_NUM_VOICE_STEPS * levels.out_l_vol)/theSink.conf1->volume_config.volume_control_config.no_of_steps);
#ifdef ENABLE_SUBWOOFER
        updateSwatVolume(levels.out_l_vol);
#endif
    }

    /* Mute if muted by host or not supported */
    mic_muted = levels.in_mute  || !USB_CLASS_ENABLED(USB_DEVICE_CLASS_TYPE_AUDIO_MICROPHONE);
    spk_muted = spk_muted || levels.out_mute || !USB_CLASS_ENABLED(USB_DEVICE_CLASS_TYPE_AUDIO_SPEAKER);

    if(mode)
    {
        if(mic_muted && spk_muted)
            *mode = AUDIO_MODE_MUTE_BOTH;
        else if(mic_muted)
            *mode = AUDIO_MODE_MUTE_MIC;
        else if(spk_muted)
            *mode = AUDIO_MODE_MUTE_SPEAKER;
        else
            *mode = AUDIO_MODE_CONNECTED;
    }

    return result;
}


/****************************************************************************
NAME
    usbAudioSinkMatch

DESCRIPTION
    Compare sink to the USB audio sink

RETURNS
    TRUE if sink matches USB audio sink, otherwise FALSE
*/
bool usbAudioSinkMatch(Sink sink)
{
    Source usb_source = NULL;
    UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_SOURCE, (uint16*)&usb_source);

    USB_DEBUG(("USB: usbAudioSinkMatch sink %x = %x, enabled = %x\n", (uint16)sink , (uint16)StreamSinkFromSource(usb_source), USB_CLASS_ENABLED(USB_DEVICE_CLASS_AUDIO) ));

    return (USB_CLASS_ENABLED(USB_DEVICE_CLASS_AUDIO) && sink && (sink == StreamSinkFromSource(usb_source)));
}


/****************************************************************************
NAME
    usbAudioGetPluginInfo

DESCRIPTION
    Get USB plugin info for current config

RETURNS
    TRUE if successful, otherwise FALSE
*/
static const usb_plugin_info* usbAudioGetPluginInfo(Task* task, usb_plugin_type type, uint8 index)
{
    switch(type)
    {
        case usb_plugin_stereo:
            *task = getA2dpPlugin(index);

            audioControlLowPowerCodecs (FALSE) ;
        break;
        case usb_plugin_mono_nb:
            *task = audioHfpGetPlugin(hfp_wbs_codec_mask_cvsd, index);

            audioControlLowPowerCodecs (TRUE) ;
        break;
        case usb_plugin_mono_wb:
            *task = audioHfpGetPlugin(hfp_wbs_codec_mask_msbc, index);

             audioControlLowPowerCodecs (TRUE) ;
        break;
        default:
            *task = NULL;
        break;
    }

    return &usb_plugins[type];
}

#if defined ENABLE_PEER && defined PEER_TWS
/****************************************************************************
NAME 
 usbCheckDeviceTrimVol

DESCRIPTION
 check whether USB streaming is ongoing and if currently active and routing audio to the device, adjust the volume up or down
 as appropriate.

RETURNS
 bool   TRUE if volume adjusted, FALSE if no streams found
    
*/
bool usbCheckDeviceTrimVol(volume_direction dir, tws_device_type tws_device)
{
    if(!usbAudioSinkMatch(theSink.routed_audio))
    {
        return FALSE;
    }
    
    VolumeUpdateDeviceTrim(dir , tws_device);

    /* Apply device trim */
    usbAudioSetVolume();
  
    return TRUE;    
}

#endif

/****************************************************************************
NAME
    usbAudioRoute

DESCRIPTION
    Connect USB audio stream

RETURNS
    void
*/
void usbAudioRoute(void)
{
    Sink sink;
    Source source;
    uint16 sampleFreq;
    UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_SOURCE, (uint16*)(&source));
    /* Note: UsbDeviceClassGetValue uses uint16 which limits max value of sample frequency to 64k (uint 16 has range 0->65536) */
    UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_SPEAKER_SAMPLE_FREQ, &sampleFreq);
    sink = StreamSinkFromSource(source);

    USB_DEBUG(("USB: Audio - sample rate = %u ",sampleFreq));
    /* Check Audio configured (sink will be NULL if VM USB not enabled) */
    if(USB_CLASS_ENABLED(USB_DEVICE_CLASS_AUDIO) && sink)
    {
        USB_DEBUG(("Configured "));
        if(usbAudioIsAttached())
        {
            USB_DEBUG(("Attached\n"));
            if(theSink.routed_audio != sink)
            {
                AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volumeDsp;
                Task plugin;
                AUDIO_MODE_T mode;
                const usb_plugin_info* plugin_info = usbAudioGetPluginInfo(&plugin, theSink.usb.config.plugin_type, theSink.usb.config.plugin_index);
                uint16 dbValueMaster;

                /* get current volume level in steps from usb interface */
                theSink.volume_levels->usb_volume.masterVolume = usbGetVolume(&mode);
                /* convert steps into db */
                dbValueMaster =  VolumeConvertStepsToDB(theSink.volume_levels->usb_volume.masterVolume, &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
                /* get current tone volume level */
                theSink.volume_levels->usb_volume.tonesVolume = VolumeConvertStepsToDB(((TonesGetToneVolume(FALSE) * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS), &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
                /* update currently routed source */
                theSink.routed_audio = sink;
                UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_SINK, (uint16*)(&theSink.cvc_params.usb_params.usb_sink));
                /* Make sure we're using correct parameters for USB */
                theSink.a2dp_link_data->a2dp_audio_connect_params.mode_params = &theSink.a2dp_link_data->a2dp_audio_mode_params;

                USB_DEBUG(("USB: Connect 0x%X 0x%X", (uint16)sink, (uint16)(theSink.cvc_params.usb_params.usb_sink)));

#ifdef ENABLE_SUBWOOFER
                /* set the sub woofer link type prior to passing to audio connect */
                theSink.a2dp_link_data->a2dp_audio_connect_params.sub_woofer_type  = AUDIO_SUB_WOOFER_NONE;
                theSink.a2dp_link_data->a2dp_audio_connect_params.sub_sink  = NULL;
                /* bits inverted in dsp plugin */
                sinkAudioSetEnhancement(MUSIC_CONFIG_SUB_WOOFER_BYPASS,TRUE);
#else
                /* no subwoofer support, set the sub woofer bypass bit in music config message sent o dsp */
                sinkAudioSetEnhancement(MUSIC_CONFIG_SUB_WOOFER_BYPASS,FALSE);
#endif

                /* use a2dp connect parameters */
                /* sample frequency is not fixed so read this from usb library */
                if(plugin_info->plugin_type == usb_plugin_stereo)
                {
#if defined ENABLE_PEER && defined PEER_TWS
                    AudioPluginFeatures PluginFeatures = theSink.conf2->audio_routing_data.PluginFeatures;
                    PluginFeatures.audio_input_routing = AUDIO_ROUTE_INTERNAL_AND_RELAY;

                    switch (sampleFreq)
                    {
                    case 16000:
                        theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = 53;
                        theSink.a2dp_link_data->a2dp_audio_connect_params.format = 0x3F;    /* 16Khz, 16 blocks, Joint Stereo, SNR, 8 subbands */
                        break;
                    case 32000:
                        theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = 53;
                        theSink.a2dp_link_data->a2dp_audio_connect_params.format = 0x7F;    /* 32Khz, 16 blocks, Joint Stereo, SNR, 8 subbands */
                        break;
                    case 44100:
                        theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = 53;
                        theSink.a2dp_link_data->a2dp_audio_connect_params.format = 0xBF;    /* 44.1Khz, 16 blocks, Joint Stereo, SNR, 8 subbands */
                        break;
                    case 48000:
                        theSink.a2dp_link_data->a2dp_audio_connect_params.bitpool = 51;
                        theSink.a2dp_link_data->a2dp_audio_connect_params.format = 0xFF;    /* 48Khz, 16 blocks, Joint Stereo, SNR, 8 subbands */
                        break;
                    default:
                        /* Unsupported rate */
                        break;
                    }

                    USB_DEBUG(("USB: AUDIO_ROUTE_INTERNAL_AND_RELAY\n"));
                    AudioConnect(plugin,
                                 sink,
                                 AUDIO_SINK_USB,
                                 theSink.codec_task,
                                 theSink.volume_levels->usb_volume.tonesVolume,
                                 sampleFreq,
                                 PluginFeatures,
                                 mode,
                                 AUDIO_ROUTE_INTERNAL,
                                 powerManagerGetLBIPM(),
                                 &theSink.a2dp_link_data->a2dp_audio_connect_params,
                                 &theSink.task);
#else

                    AudioConnect(plugin,
                                 sink,
                                 AUDIO_SINK_USB,
                                 theSink.codec_task,
                                 theSink.volume_levels->usb_volume.tonesVolume,
                                 sampleFreq,
                                 theSink.conf2->audio_routing_data.PluginFeatures,
                                 mode,
                                 AUDIO_ROUTE_INTERNAL,
                                 powerManagerGetLBIPM(),
                                 &theSink.a2dp_link_data->a2dp_audio_connect_params,
                                 &theSink.task);
#endif
                }
                /* all other plugins use cvc connect parameters */
                else
                {
                    AudioConnect(plugin,
                                 sink,
                                 AUDIO_SINK_USB,
                                 theSink.codec_task,
                                 theSink.volume_levels->usb_volume.tonesVolume,
                                 sampleFreq,
                                 theSink.conf2->audio_routing_data.PluginFeatures,
                                 mode,
                                 AUDIO_ROUTE_INTERNAL,
                                 powerManagerGetLBIPM(),
                                 &theSink.cvc_params,
                                 &theSink.task);
                }
                
                /* use a2dp connect parameters */
                AudioSetMode(mode, &theSink.a2dp_link_data->a2dp_audio_mode_params);

                /* update volume via a2dp common plugin */
                volumeDsp.volume_type = theSink.conf1->volume_config.volume_control_config.volume_type;
                volumeDsp.codec_task = theSink.codec_task;
                volumeDsp.master_gain = dbValueMaster;
                volumeDsp.tones_gain =  theSink.volume_levels->usb_volume.tonesVolume;
                volumeDsp.system_gain = theSink.conf1->volume_config.volume_control_config.system_volume;
                volumeDsp.trim_gain_left = theSink.conf1->volume_config.volume_control_config.trim_volume_left;
                volumeDsp.trim_gain_right= theSink.conf1->volume_config.volume_control_config.trim_volume_right;
                volumeDsp.device_trim_master = theSink.conf1->volume_config.volume_control_config.device_trim_master;
                volumeDsp.device_trim_slave = theSink.conf1->volume_config.volume_control_config.device_trim_slave;
                volumeDsp.mute_active = theSink.sink_mute_status;

                AudioSetVolumeA2DP ( &volumeDsp);

#ifdef ENABLE_SUBWOOFER
                /* set subwoofer volume level */
                updateSwatVolume(theSink.volume_levels->usb_volume.masterVolume);
#endif
            }
        }
    }
    USB_DEBUG(("\n"));
}

/*************************************************************************
NAME    
    usbAudioSuspend
    
DESCRIPTION
    Issue HID consumer control command to attempt to pause current USB stream

RETURNS
    None
    
**************************************************************************/
void usbAudioSuspend (void)
{
    /* If speaker is in use or not marked as suspended then pause */
    if (theSink.usb.spkr_active || (theSink.usb.audio_suspend_state == usb_audio_suspend_none))
    {
        usbSetAudioSuspendState(usb_audio_suspend_local);
        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PAUSE);
        
        /* Ensure audio routing is kicked as we may not always get a notification that streaming has ceased via USB */
        MessageSend(&theSink.task, EventSysCheckAudioRouting, 0);
    }
}

/*************************************************************************
NAME    
    usbAudioResume
    
DESCRIPTION
    Issue HID consumer control command to attempt to resume current USB stream

RETURNS
    None
    
**************************************************************************/
void usbAudioResume (void)
{
    /* If speaker is not use or marked as suspended then resume */
    if (!theSink.usb.spkr_active || (theSink.usb.audio_suspend_state != usb_audio_suspend_none))
    {
        usbSetAudioSuspendState(usb_audio_suspend_none);
        UsbDeviceClassSendEvent(USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PLAY);
        
        /* Ensure audio routing is kicked as we may not always get a notification that streaming has started via USB */
        MessageSend(&theSink.task, EventSysCheckAudioRouting, 0);
    }
}

/****************************************************************************
NAME
    usbAudioDisconnect

DESCRIPTION
    Disconnect USB audio stream

RETURNS
    void
*/
void usbAudioDisconnect(void)
{
    if(usbAudioSinkMatch(theSink.routed_audio))
    {
        USB_DEBUG(("USB: Disconnect 0x%X\n", (uint16)theSink.routed_audio));
        AudioDisconnect();
        theSink.routed_audio = 0;
        
        /* If speaker is in use then pause */
        usbAudioSuspend();
        
#ifdef ENABLE_PEER
        {
            /*If the USB has disconnected then notify this to the peer device */
            audio_src_conn_state_t  AudioSrcStatus;
            AudioSrcStatus.src = USB_AUDIO;
            AudioSrcStatus.isConnected = FALSE;
            updatePeerAudioConnStatus(AudioSrcStatus);
        }
#endif
    }
}


/****************************************************************************
NAME
    usbAudioSetVolume

DESCRIPTION
    Set USB audio volume

RETURNS
    void
*/
void usbAudioSetVolume(void)
{
    if(usbAudioSinkMatch(theSink.routed_audio) && USB_CLASS_ENABLED(USB_DEVICE_CLASS_AUDIO))
    {
        AUDIO_PLUGIN_SET_VOLUME_A2DP_MSG_T volumeDsp;
        Task plugin;
        AUDIO_MODE_T mode;
        uint16 dbValueMaster;

        /* get usb volume in steps */
        theSink.volume_levels->usb_volume.masterVolume = usbGetVolume(&mode);

        /* check for mute state */
        if(theSink.volume_levels->usb_volume.masterVolume == VOLUME_A2DP_MIN_LEVEL)
        {
            /* muted state, set master gain to -120dB */
            dbValueMaster = VOLUME_MUTE_DB;
            dbValueMaster = -7100;
        }
        else
        {        
            /* convert to dB */
            dbValueMaster =  VolumeConvertStepsToDB(theSink.volume_levels->usb_volume.masterVolume, &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
        }
        
        /* determine tone volume */
        theSink.volume_levels->usb_volume.tonesVolume = VolumeConvertStepsToDB(((TonesGetToneVolume(FALSE) * theSink.conf1->volume_config.volume_control_config.no_of_steps)/VOLUME_NUM_VOICE_STEPS), &theSink.conf1->volume_config.volume_control_config, DSP_DB_SCALE);
        /* get usb plugin being used */
        usbAudioGetPluginInfo(&plugin, theSink.usb.config.plugin_type, theSink.usb.config.plugin_index);
        /* update volume via a2dp common plugin */
        volumeDsp.volume_type = theSink.conf1->volume_config.volume_control_config.volume_type;
        volumeDsp.codec_task = theSink.codec_task;
        volumeDsp.master_gain = dbValueMaster;
        volumeDsp.tones_gain =  theSink.volume_levels->usb_volume.tonesVolume;
        volumeDsp.system_gain = theSink.conf1->volume_config.volume_control_config.system_volume;
        volumeDsp.trim_gain_left = theSink.conf1->volume_config.volume_control_config.trim_volume_left;
        volumeDsp.trim_gain_right= theSink.conf1->volume_config.volume_control_config.trim_volume_right;
        volumeDsp.device_trim_master = theSink.conf1->volume_config.volume_control_config.device_trim_master;
        volumeDsp.device_trim_slave = theSink.conf1->volume_config.volume_control_config.device_trim_slave;
        volumeDsp.mute_active = theSink.sink_mute_status;

        AudioSetVolumeA2DP ( &volumeDsp);
        

    }
}


/****************************************************************************
NAME
    usbAudioGetMode

DESCRIPTION
    Get the current USB audio mode if USB in use

RETURNS
    void
*/
void usbAudioGetMode(AUDIO_MODE_T* mode)
{
    if(usbAudioSinkMatch(theSink.routed_audio) && (theSink.usb.config.plugin_type == usb_plugin_stereo))
    {
        (void)usbGetVolume(mode);
    }
}

/****************************************************************************
NAME
    usbGetAudioSink

DESCRIPTION
    check USB state and return sink if available

RETURNS
   sink if available, otherwise 0
*/
Sink usbGetAudioSink(void)
{
    Source usb_source = NULL;
    Sink sink = NULL;
    UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_VALUE_AUDIO_SOURCE, (uint16*)&usb_source);

    /* if the usb lead is attached and the speaker is active, try to obtain the audio sink */
    if((theSink.usb.config.audio_always_on)||((usbAudioIsAttached())&&(theSink.usb.spkr_active)))
    {
        /* attempt to obtain USB audio sink */
        sink = StreamSinkFromSource(usb_source);
        USB_DEBUG(("USB: usbGetAudioSink sink %x, enabled = %x\n", (uint16)sink , USB_CLASS_ENABLED(USB_DEVICE_CLASS_AUDIO) ));
    }
    /* USB not attached */
    else
        USB_DEBUG(("USB: usbGetAudioSink sink %x, enabled = %x, speaker active = %x\n", (uint16)sink , USB_CLASS_ENABLED(USB_DEVICE_CLASS_AUDIO), theSink.usb.spkr_active ));

    return sink;
}

/****************************************************************************
NAME
    usbAudioSetSpeakerSampleRate

DESCRIPTION
    check if the sample rate has change, whether usb audio is currently streaming
    , if so a restart of the sbc_decoder is necessary to run at the new indicated rate

RETURNS
    none
*/
void usbAudioSetSpeakerSampleRate(uint16 sample_rate)
{
    /* determine if the USB audio is currently being streamed by the DSP and the dsp
       is in the running state */
    if((theSink.rundata->routed_audio_source == audio_source_USB)&&
       (GetAudioPlugin() == (TaskData *)&csr_sbc_decoder_plugin)&&
       (GetCurrentDspStatus() == DSP_RUNNING))
    {
        uint32 current_sampling_rate = AudioGetA2DPSampleRate();
        
        USB_DEBUG(("USB: Set Spk Sample Rate - DSP running - now: %ld new: %ld\n", current_sampling_rate, (uint32)sample_rate));

        /* dsp is loaded and running the usb decoder, determine if the new sample
           rate is different to that currently being used by the decoder */
        if(current_sampling_rate)
        {
            if(sample_rate != current_sampling_rate)
            {
                USB_DEBUG(("USB: Set Spk Sample Rate - DSP running - *** needs update *** - AudioDisconnect\n"));

                /* the sample rate is different to that currently being used, it is necessary
                   to restart the decoder to use the correct audio sample rate */
                AudioDisconnect();

                USB_DEBUG(("USB: Set Spk Sample Rate - DSP running - *** needs update *** - Switch To USB\n"));
                /* audio no longer routed */
                theSink.rundata->routed_audio_source = audio_source_none;
                theSink.routed_audio = 0;
                MessageCancelAll (&theSink.task, EventUsrSelectAudioSourceUSB);
                /* re-route USB audio */
                MessageSend( &theSink.task , EventUsrSelectAudioSourceUSB , 0);
            }
        }
        else
        {
            /*Current sampling rate is set to 0, which means that the audio decoder plugin has disconnected */
            /* reschedule the message to occur after the dsp has completed loading */
            MAKE_USB_DEVICE_CLASS_MESSAGE(USB_DEVICE_CLASS_SAMPLE_RATE);
            message->sample_rate = sample_rate;
            MessageCancelAll (&theSink.task, USB_DEVICE_CLASS_MSG_SPEAKER_SAMPLE_RATE_IND);
            MessageSendLater(&theSink.task, USB_DEVICE_CLASS_MSG_SPEAKER_SAMPLE_RATE_IND, message, 100);
            USB_DEBUG(("USB: Set Spk Sample Rate - DSP Loading - Reschedule\n"));
        }
    }
    /* check if dsp is in the process of being loaded but not currently running
       in which case it needs to be restarted with the new sample rate */
    else if((theSink.rundata->routed_audio_source == audio_source_USB)&&
            (GetAudioPlugin() == (TaskData *)&csr_sbc_decoder_plugin)&&
            ((GetCurrentDspStatus() == DSP_LOADING)||(GetCurrentDspStatus() == DSP_LOADED_IDLE)))
    {
        /* reschedule the message to occur after the dsp has completed loading */
        MAKE_USB_DEVICE_CLASS_MESSAGE(USB_DEVICE_CLASS_SAMPLE_RATE);
        message->sample_rate = sample_rate;
        MessageCancelAll (&theSink.task, USB_DEVICE_CLASS_MSG_SPEAKER_SAMPLE_RATE_IND);
        MessageSendLater(&theSink.task, USB_DEVICE_CLASS_MSG_SPEAKER_SAMPLE_RATE_IND, message, 100);
        USB_DEBUG(("USB: Set Spk Sample Rate - DSP Loading - Reschedule\n"));
    }
    else
    {
        USB_DEBUG(("USB: Set Spk Sample Rate - DSP NOT running : %x\n",GetCurrentDspStatus()));
    }

}

/****************************************************************************
NAME
    usbAudioSetMicSampleRate

DESCRIPTION
    check if the sample rate has change, whether usb audio is currently streaming
    , if so a restart of the sbc_decoder may be necessary to run at the new indicated rate

RETURNS
    none
*/
void usbAudioSetMicSampleRate(uint16 sample_rate)
{

}

#endif /* ENABLE_USB_AUDIO */
#endif /* ENABLE_USB */
