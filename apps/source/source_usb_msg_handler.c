/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_usb_msg_handler.c

DESCRIPTION
    USB message handling.
    
*/


/* header for this file */
#include "source_usb_msg_handler.h"
/* application header files */
#include "source_app_msg_handler.h"
#include "source_debug.h"
#include "source_private.h"
#include "source_usb.h"
/* profile/library headers */
#include <codec.h>
#include <usb_device_class.h>
/* VM headers */
#include <panic.h>


#ifdef DEBUG_USB_MSG
    #define USB_MSG_DEBUG(x) DEBUG(x)
#else
    #define USB_MSG_DEBUG(x)
#endif     


/***************************************************************************
Functions
****************************************************************************
*/

/****************************************************************************
NAME    
    usb_msg_handler - Handles USB messages
*/
void usb_msg_handler(Task task, MessageId id, Message message)
{  
    switch (id)
    {
        /* message indicating that USB has enumerated */
        case MESSAGE_USB_ENUMERATED:
        {
            USB_MSG_DEBUG(("MESSAGE_USB_ENUMERATED\n"));
        }
        break;
        
        /* message that indicates an alternative setting is applied on a USB interface */
        case MESSAGE_USB_ALT_INTERFACE:
        {
            uint16 interface_id;
            MessageUsbAltInterface* ind = (MessageUsbAltInterface*)message;
            bool audio_active = FALSE;
            USB_MSG_DEBUG(("MESSAGE_USB_ALT_INTERFACE %d %d\n", ind->interface, ind->altsetting));
            
            UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_MIC_INTERFACE_ID, &interface_id);
            if(interface_id == ind->interface)
            {
                USB_MSG_DEBUG(("Mic ID if[%d] active[%d]\n", interface_id, ind->altsetting));     
                if (ind->altsetting)
                {
                    MessageCancelAll(&theSource->app_data.appTask, APP_MIC_AUDIO_INACTIVE);
                    MessageSendLater(&theSource->app_data.appTask, APP_MIC_AUDIO_ACTIVE, 0, MIC_AUDIO_ACTIVE_DELAY);
                    audio_active = TRUE;
                }
                else
                {
                    MessageCancelAll(&theSource->app_data.appTask, APP_MIC_AUDIO_ACTIVE);
                    MessageSendLater(&theSource->app_data.appTask, APP_MIC_AUDIO_INACTIVE, 0, MIC_AUDIO_INACTIVE_DELAY);
                }
            }
            UsbDeviceClassGetValue(USB_DEVICE_CLASS_GET_SPEAKER_INTERFACE_ID, &interface_id);
            if(interface_id == ind->interface)
            {
                USB_MSG_DEBUG(("Speaker ID if[%d] active[%d]\n", interface_id, ind->altsetting));    
                if (ind->altsetting)
                {
                    audio_active = TRUE;
                }
            }
            
            if (audio_active)
            {
                /* USB audio is active - send active message so that Bluetooth audio can be routed */                
                theSource->audio_data.audio_usb_active = TRUE;
                MessageCancelFirst(&theSource->app_data.appTask, APP_USB_AUDIO_INACTIVE);
                MessageSendLater(&theSource->app_data.appTask, APP_USB_AUDIO_ACTIVE, 0, USB_AUDIO_ACTIVE_DELAY);
            }
            else
            {
                /* USB audio is inactive - start the audio active timer and when this expires the Bluetooth audio can be suspended */
                theSource->audio_data.audio_usb_active = FALSE;
                audio_start_active_timer();
            }
        }
        break;
        
        /* message containing the USB audio levels */
        case USB_DEVICE_CLASS_MSG_AUDIO_LEVELS_IND:
        {
            USB_MSG_DEBUG(("USB_DEVICE_CLASS_MSG_AUDIO_LEVELS_IND\n"));
            usb_get_audio_levels_update_headset(TRUE);
        }
        break;
             
        /* message containing an incoming USB report */
        case USB_DEVICE_CLASS_MSG_REPORT_IND:
        {
            USB_MSG_DEBUG(("USB_DEVICE_CLASS_MSG_REPORT_IND\n"));
            usb_handle_report((USB_DEVICE_CLASS_MSG_REPORT_IND_T *)message);
        }
        break;       
        
        /* message indicating that USB has suspended */
        case MESSAGE_USB_SUSPENDED: /* will not be received if bus powered USB device */
        {
            USB_MSG_DEBUG(("MESSAGE_USB_SUSPENDED\n"));
        }
        break;
        
        default:       
        {
	    	USB_MSG_DEBUG(("USB MSG Unhandled[0x%x]\n",id));
        }
        break;
    }
}
