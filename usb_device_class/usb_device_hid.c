#ifndef USB_DEVICE_CLASS_REMOVE_HID

/*#define DEBUG_PRINT_ENABLED*/

#include <message.h>
#include <panic.h>
#include <sink.h>
#include <source.h>
#include <string.h>
#include <stream.h>
#include <stdlib.h>
#include <usb.h>

#include "usb_device_class.h"
#include "usb_device_class_private.h"
#include "usb_device_hid.h"

#include <print.h>


static const usb_device_class_hid_consumer_transport_config* usb_hid_consumer_config = NULL;


static const UsbCodes usb_codes_hid_no_boot = {B_INTERFACE_CLASS_HID, /* bInterfaceClass */
                                               B_INTERFACE_SUB_CLASS_HID_NO_BOOT, /* bInterfaceSubClass */
                                               B_INTERFACE_PROTOCOL_HID_NO_BOOT, /* bInterfaceProtocol */
                                               I_INTERFACE_INDEX /* iInterface */
                                               };

/* HID Report Descriptor - Consumer Transport Control Device */
static const uint8 report_descriptor_hid_consumer_transport[] = 
{
    0x05, 0x0C,                  /* USAGE_PAGE (Consumer Devices) */
    0x09, 0x01,                  /* USAGE (Consumer Control) */
    0xa1, 0x01,                  /* COLLECTION (Application) */
    
    0x85, 0x01,                  /*   REPORT_ID (1) */
    
    0x15, 0x00,                  /*   LOGICAL_MINIMUM (0) */
    0x25, 0x01,                  /*   LOGICAL_MAXIMUM (1) */
    0x09, 0xcd,                  /*   USAGE (Play/Pause - OSC) */
    0x09, 0xb5,                  /*   USAGE (Next Track - OSC) */
    0x09, 0xb6,                  /*   USAGE (Previous Track - OSC) */
    0x09, 0xb7,                  /*   USAGE (Stop - OSC) */
    0x75, 0x01,                  /*   REPORT_SIZE (1) */
    0x95, 0x04,                  /*   REPORT_COUNT (4) */
    0x81, 0x02,                  /*   INPUT (Data,Var,Abs) */
    
    0x15, 0x00,                  /*   LOGICAL_MINIMUM (0) */
    0x25, 0x01,                  /*   LOGICAL_MAXIMUM (1) */
    0x09, 0xb0,                  /*   USAGE (Play - OOC) */
    0x09, 0xb1,                  /*   USAGE (Pause - OOC) */
    0x09, 0xb3,                  /*   USAGE (Fast Forward -OOC) */
    0x09, 0xb4,                  /*   USAGE (Rewind - OOC) */
    0x75, 0x01,                  /*   REPORT_SIZE (1) */
    0x95, 0x04,                  /*   REPORT_COUNT (4) */
    0x81, 0x22,                  /*   INPUT (Data,Var,Abs,NoPref) */
    
    0x15, 0x00,                  /*   LOGICAL_MINIMUM (0) */
    0x25, 0x01,                  /*   LOGICAL_MAXIMUM (1) */
    0x09, 0xe9,                  /*   USAGE (Volume Increment - RTC) */
    0x09, 0xea,                  /*   USAGE (Volume Decrement - RTC) */
    0x75, 0x01,                  /*   REPORT_SIZE (1) */
    0x95, 0x02,                  /*   REPORT_COUNT (2) */    
    0x81, 0x02,                  /*   INPUT (Data,Var,Abs,Bit Field) */
    0x09, 0xe2,                  /*   USAGE (Mute - OOC) */
    
    0x95, 0x01,                  /*   REPORT_COUNT (1) */    
    0x81, 0x06,                  /*   INPUT (Data,Var,Rel,Bit Field) */
    
    0x95, 0x05,                  /*   REPORT_COUNT (5) */
    0x81, 0x01,                  /*   INPUT (Const) */
    
    0xc0                        /* END_COLLECTION */
};

/* USB HID class descriptor - Consumer Transport Control Device*/
static const uint8 interface_descriptor_hid_consumer_transport[] =
{
    HID_DESCRIPTOR_LENGTH,              /* bLength */
    B_DESCRIPTOR_TYPE_HID,              /* bDescriptorType */
    0x11, 0x01,                         /* bcdHID */
    0,                                  /* bCountryCode */
    1,                                  /* bNumDescriptors */
    B_DESCRIPTOR_TYPE_HID_REPORT,       /* bDescriptorType */
    sizeof(report_descriptor_hid_consumer_transport),   /* wDescriptorLength */
    0                                   /* wDescriptorLength */
};

/* USB HID endpoint information */
static const EndPointInfo epinfo_hid_consumer_transport[] =
{
    {        
        end_point_int_out, /* address */
        end_point_attr_int, /* attributes */
        16, /* max packet size */
        1, /* poll_interval */
        0, /* data to be appended */
        0, /* length of data appended */
    }
};

static const usb_device_class_hid_consumer_transport_config usb_hid_config_consumer_transport =
{
    {interface_descriptor_hid_consumer_transport,
    sizeof(interface_descriptor_hid_consumer_transport),
    epinfo_hid_consumer_transport},
    {report_descriptor_hid_consumer_transport,
    sizeof(report_descriptor_hid_consumer_transport),
    NULL}
};


/* USB HID keyboard class descriptor */
static const uint8 interface_descriptor_hid_keybd[HID_DESCRIPTOR_LENGTH] =
{
    HID_DESCRIPTOR_LENGTH,              /* bLength */
    B_DESCRIPTOR_TYPE_HID,              /* bDescriptorType */
    0x11, 0x01,                         /* bcdHID */
    0,                                  /* bCountryCode */
    1,                                  /* bNumDescriptors */
    B_DESCRIPTOR_TYPE_HID_REPORT,       /* bDescriptorType */
    HID_KEYBD_REPORT_DESCRIPTOR_LENGTH, /* wDescriptorLength */
    0                                   /* wDescriptorLength */
};

/* HID Keyboard Report Descriptor */
static const uint8 report_descriptor_hid_keybd[] =
{
    0x05, 0x01,                    /* USAGE_PAGE (Generic Desktop) */
    0x09, 0x06,                    /* USAGE (Keyboard) */
    0xa1, 0x01,                    /* COLLECTION (Application) */
    0x05, 0x07,                    /*   USAGE_PAGE (Keyboard) */

    /* 8 bits - Modifiers (alt, shift etc) */
    0x19, 0xe0,                    /*   USAGE_MINIMUM (Keyboard LeftControl) */
    0x29, 0xe7,                    /*   USAGE_MAXIMUM (Keyboard Right GUI) */
    0x15, 0x00,                    /*   LOGICAL_MINIMUM (0) */
    0x25, 0x01,                    /*   LOGICAL_MAXIMUM (1) */
    0x75, 0x01,                    /*   REPORT_SIZE (1) */
    0x95, 0x08,                    /*   REPORT_COUNT (8) */
    0x81, 0x02,                    /*   INPUT (Data,Var,Abs) */

    /* 8 bits - Reserved byte */
    0x75, 0x08,                    /*   REPORT_SIZE (8) */
    0x95, 0x01,                    /*   REPORT_COUNT (1) */
    0x81, 0x01,                    /*   INPUT (Const) */

    /* 6 x 8 bits - Key states */
    0x19, 0x00,                    /*   USAGE_MINIMUM (Reserved (no event indicated)) */
    0x29, 0x91,                    /*   USAGE_MAXIMUM (Keyboard Application) */
    0x15, 0x00,                    /*   LOGICAL_MINIMUM (0) */
    0x26, 0xFF, 0x00,              /*   LOGICAL_MAXIMUM (255) */
    0x75, 0x08,                    /*   REPORT_SIZE */
    0x95, 0x06,                    /*   REPORT_COUNT */
    0x81, 0x00,                    /*   INPUT (Data,Ary,Abs) */
    
    0xc0                           /* END_COLLECTION */
};

/* USB HID endpoint information, no consumer */
static const EndPointInfo epinfo_hid_keybd_no_consumer[] =
{
    {
        end_point_int_out, /* address */
        end_point_attr_int, /* attributes */
        16, /* max packet size */
        1, /* poll_interval */
        0, /* data to be appended */
        0, /* length of data appended */
    }
};

/* USB HID endpoint information, with consumer */
static const EndPointInfo epinfo_hid_keybd_with_consumer[] =
{
    {
        end_point_int_out2, /* address */
        end_point_attr_int, /* attributes */
        16, /* max packet size */
        1, /* poll_interval */
        0, /* data to be appended */
        0, /* length of data appended */
    }
};


static bool usbEnumerateHidConsumerTransportControl(void);
static bool usbEnumerateHidKeyboard(bool consumer_active);
static void hidConsumerHandler(Task task, MessageId id, Message message);
static void hidKeyboardHandler(Task task, MessageId id, Message message);
static void handleHidClassRequest(Source source, usb_device_class_type class_type);
static void usbSendDefaultHidConsumerOscEvent(uint16 key);
static void usbSendDefaultHidConsumerOocEvent(uint16 key, uint16 state);
static void usbSendDefaultHidKeyboardModifierEvent(uint16 modifier, uint16 key);

 
static bool usbEnumerateHidConsumerTransportControl(void)
{
    if (!usb_hid_consumer_config)
    {
        usb_hid_consumer_config = &usb_hid_config_consumer_transport;        
        PRINT(("USB: HID consumer default descriptors\n"));
    }
    
    device->usb_interface[usb_interface_hid_consumer_transport] = UsbAddInterface(&usb_codes_hid_no_boot, B_DESCRIPTOR_TYPE_HID, usb_hid_consumer_config->interface.descriptor, usb_hid_consumer_config->interface.size_descriptor);
    if (device->usb_interface[usb_interface_hid_consumer_transport] == usb_interface_error)
        return FALSE;

    /* Register HID Consumer Control Device report descriptor with the interface */
    if (UsbAddDescriptor(device->usb_interface[usb_interface_hid_consumer_transport], B_DESCRIPTOR_TYPE_HID_REPORT, usb_hid_consumer_config->report.descriptor, usb_hid_consumer_config->report.size_descriptor) == FALSE)
        return FALSE;
    /* Add required endpoints to the interface */
    if (UsbAddEndPoints(device->usb_interface[usb_interface_hid_consumer_transport], 1, usb_hid_consumer_config->interface.end_point_info) == FALSE)
        return FALSE;
    
    device->usb_task[usb_task_hid_consumer].handler = hidConsumerHandler;
    (void) MessageSinkTask(StreamUsbClassSink(device->usb_interface[usb_interface_hid_consumer_transport]), &device->usb_task[usb_task_hid_consumer]);
    
    return TRUE;
}


static bool usbEnumerateHidKeyboard(bool consumer_active)
{
    device->usb_interface[usb_interface_hid_keyboard] = UsbAddInterface(&usb_codes_hid_no_boot, B_DESCRIPTOR_TYPE_HID, interface_descriptor_hid_keybd, sizeof(interface_descriptor_hid_keybd));
    if (device->usb_interface[usb_interface_hid_keyboard] == usb_interface_error)
        return FALSE;

    /* Register HID Keyboard report descriptor with the interface */
    if (UsbAddDescriptor(device->usb_interface[usb_interface_hid_keyboard], B_DESCRIPTOR_TYPE_HID_REPORT, report_descriptor_hid_keybd, sizeof(report_descriptor_hid_keybd)) == FALSE)
        return FALSE;
    /* Add required endpoints to the interface */
    if (consumer_active)
    {
        if (UsbAddEndPoints(device->usb_interface[usb_interface_hid_keyboard], 1, epinfo_hid_keybd_with_consumer) == FALSE)
            return FALSE;
    }
    else
    {
        if (UsbAddEndPoints(device->usb_interface[usb_interface_hid_keyboard], 1, epinfo_hid_keybd_no_consumer) == FALSE)
            return FALSE;
    }

    device->usb_task[usb_task_hid_keyboard].handler = hidKeyboardHandler;
    (void) MessageSinkTask(StreamUsbClassSink(device->usb_interface[usb_interface_hid_keyboard]), &device->usb_task[usb_task_hid_keyboard]);
    
    return TRUE;
}
 

static void hidConsumerHandler(Task task, MessageId id, Message message)
{
    if (id == MESSAGE_MORE_DATA)
    {
        PRINT(("USB: MESSAGE_MORE_DATA hid consumer\n"));
        handleHidClassRequest(StreamUsbClassSource(device->usb_interface[usb_interface_hid_consumer_transport]), USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL);
    }
}


static void hidKeyboardHandler(Task task, MessageId id, Message message)
{
    if (id == MESSAGE_MORE_DATA)
    {
        PRINT(("USB: MESSAGE_MORE_DATA hid keyboard\n"));
        handleHidClassRequest(StreamUsbClassSource(device->usb_interface[usb_interface_hid_keyboard]), USB_DEVICE_CLASS_TYPE_HID_KEYBOARD);
    }
}
 
 
static void handleHidClassRequest(Source source, usb_device_class_type class_type)
{
    static uint8 idle_rate = 0;
    
    {    
        Sink sink = StreamSinkFromSource(source);
        uint16 packet_size;

        while ((packet_size = SourceBoundary(source)) != 0)
        {
            /* Build the respnse. It must contain the original request, so copy 
               from the source header. */
            UsbResponse resp;
            memcpy(&resp.original_request, SourceMapHeader(source), sizeof(UsbRequest));
        
            /* Set the response fields to default values to make the code below simpler */
            resp.success = FALSE;
            resp.data_length = 0;
        
            switch (resp.original_request.bRequest)
            {
                /* GET_REPORT */
                case 0x01:
                {
                    PRINT(("USB: HID Get_Report src=0x%X wValue=0x%X wIndex=0x%X wLength=0x%X\n", (uint16)source, resp.original_request.wValue, resp.original_request.wIndex, resp.original_request.wLength));
                    break;
                }
            
                /* GET_IDLE */
                case 0x02:
                {
                    uint8 *out;
                    if ((out = claimSink(sink, 1)) != 0)
                    {
                        PRINT(("USB: HID Get_Idle src=0x%X wValue=0x%X wIndex=0x%X\n", (uint16)source, resp.original_request.wValue, resp.original_request.wIndex));
                        out[0] = idle_rate;
                        resp.success = TRUE;
                        resp.data_length = 1;                
                    }
                    break;
                }
            
                /* SET_REPORT */
                case 0x09:
                {
                    const uint8 *in = SourceMap(source);                    
                    uint16 size_data = resp.original_request.wLength;                
                    uint8 report_id = resp.original_request.wValue & 0xff;
                    PRINT(("USB: HID Set_Report src=0x%X wValue=0x%X wIndex=0x%X wLength=0x%X -> \n", (uint16)source, resp.original_request.wValue, resp.original_request.wIndex, resp.original_request.wLength));
                  
                    resp.success = TRUE;
                                                            
                    if (size_data)
                    {
                        if (class_type == USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL)
                        {
                            USB_DEVICE_CLASS_MSG_REPORT_IND_T *message = PanicUnlessMalloc(sizeof(USB_DEVICE_CLASS_MSG_REPORT_IND_T) + size_data);
                            uint16 source_size = SourceSize(source);
                            
                            PRINT(("    send report ind source_size[0x%x]\n", source_size));
                            
                            message->class_type = class_type;
                            message->report_id = report_id;
                            message->size_report = size_data;
                            
                            in = SourceMap(source);  
                            if (source_size < message->size_report)
                            {
                                message->size_report = source_size;                                    
                            }
                            memmove(message->report, in, message->size_report);
                            MessageSend(device->app_task, USB_DEVICE_CLASS_MSG_REPORT_IND, message);
                            PRINT(("    sent report ind to Task [0x%x]\n", (uint16)device->app_task));
                        }
                    }                                     
                    break;
                }
            
                /* SET_IDLE */
                case 0x0A:    
                {
                    PRINT(("USB: HID Set_Idle src=0x%X wValue=0x%X wIndex=0x%X\n", (uint16)source, resp.original_request.wValue, resp.original_request.wIndex));
                    idle_rate = resp.original_request.wValue >> 8;
                    resp.success = TRUE;
                    break;
                }
            
                default:
                {
                    PRINT(("USB: HID req=0x%X src=0x%X wValue=0x%X wIndex=0x%X wLength=0x%X\n", resp.original_request.bRequest, (uint16)source, resp.original_request.wValue, resp.original_request.wIndex, resp.original_request.wLength));
                    break;            
                }
            }
        
            /* Send response */
            if (resp.data_length)
            {
                (void)SinkFlushHeader(sink, resp.data_length, (uint16 *)&resp, sizeof(UsbResponse));
            }
            else
            {
                   /* Sink packets can never be zero-length, so flush a dummy byte */
                (void) SinkClaim(sink, 1);
                (void) SinkFlushHeader(sink, 1, (uint16 *) &resp, sizeof(UsbResponse));          
            }   

            /* Discard the original request */
              SourceDrop(source, packet_size);
        }
    }
}


static void usbSendDefaultHidConsumerOscEvent(uint16 key)
{
    uint16 size_params = 3;
    uint8 params[3];
                
    params[0] = 1;          /* REPORT ID */
    params[1] = key;        /* key code */
    params[2] = key >> 8;   /* key code */
    usbSendRawEventHidKeycode(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, size_params, params);
    params[1] = 0; /* key released */
    params[2] = 0; /* key released */
    usbSendRawEventHidKeycode(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, size_params, params);
}


static void usbSendDefaultHidConsumerOocEvent(uint16 key, uint16 state)
{
    uint16 size_params = 3;
    uint8 params[3];
    
    params[0] = 1; /* REPORT ID */
    
    if (state)
    {
        params[1] = key;        /* key on code */
        params[2] = key >> 8;   /* key on code */
    }
    else
    {
        params[1] = 0; /* key released */
        params[2] = 0; /* key released */
    }
    usbSendRawEventHidKeycode(USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL, size_params, params);
}


static void usbSendDefaultHidKeyboardModifierEvent(uint16 modifier, uint16 key)
{
    uint16 size_params = 8;
    uint8 params[8];
    
    memset(params, 0, size_params);
                
    params[0] = modifier; /* modifier */
    params[2] = key; /* key code */
    usbSendRawEventHidKeycode(USB_DEVICE_CLASS_TYPE_HID_KEYBOARD, size_params, params);
    params[0] = 0; /* key released */
    params[2] = 0; /* key released */
    usbSendRawEventHidKeycode(USB_DEVICE_CLASS_TYPE_HID_KEYBOARD, size_params, params);
}


bool usbEnumerateHid(uint16 usb_device_class)
{
    if ((usb_device_class & USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL) && (usb_device_class & USB_DEVICE_CLASS_TYPE_HID_KEYBOARD))
    {
        PRINT(("USB: Enumerate consumer/keyboard\n"));
        if (usbEnumerateHidConsumerTransportControl() && usbEnumerateHidKeyboard(TRUE))
            return TRUE;
        else
            return FALSE;
    }
    else if (usb_device_class & USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL)
    {
        PRINT(("USB: Enumerate consumer\n"));
        return usbEnumerateHidConsumerTransportControl();
    }
    else if (usb_device_class & USB_DEVICE_CLASS_TYPE_HID_KEYBOARD)
    {
        PRINT(("USB: Enumerate keyboard\n"));
        return usbEnumerateHidKeyboard(FALSE);
    }
    
    return FALSE;
}


bool usbConfigureHidConsumerTransport(usb_device_class_config config, const usb_device_class_hid_consumer_transport_config* params)
{
    /* Sanity check request */
    if(!params || (config != USB_DEVICE_CLASS_CONFIG_HID_CONSUMER_TRANSPORT_DESCRIPTORS))
        return FALSE;
    /* Update audio config */
    usb_hid_consumer_config = params;
    
    PRINT(("USB: HID consumer configured to use supplied descriptors\n"));
    
    return TRUE;
}


bool usbSendRawEventHidKeycode(usb_device_class_type type, uint16 size_params, const uint8 *params)
{
    uint8 *ptr;
    uint16 i;
    Sink sink;
    
    if ((type & USB_DEVICE_CLASS_TYPE_HID_KEYBOARD) && (device->usb_classes & USB_DEVICE_CLASS_TYPE_HID_CONSUMER_TRANSPORT_CONTROL))
        sink = StreamUsbEndPointSink(end_point_int_out2);
    else        
        sink = StreamUsbEndPointSink(end_point_int_out);
    
    if ((ptr = claimSink(sink, size_params)) != 0)
    {
        for (i = 0; i < size_params; i++)
        {
            ptr[i] = params[i];            
        }
        /* Flush data */    
        (void) SinkFlush(sink, size_params);

        PRINT(("USB: HID sent event\n"));
    }
    
    return FALSE;
}


usb_device_class_status usbSendDefaultHidConsumerEvent(usb_device_class_event event)
{
    switch (event)
    {
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PLAY_PAUSE:
        {              
            usbSendDefaultHidConsumerOscEvent(1 /* PLAY/PAUSE */);                
            return usb_device_class_status_success;
        }    
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_STOP:
        {              
            usbSendDefaultHidConsumerOscEvent(8 /* STOP */);                
            return usb_device_class_status_success;
        }      
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_NEXT_TRACK:
        {
            usbSendDefaultHidConsumerOscEvent(2 /* NEXT TRACK */);
            return usb_device_class_status_success;
        }
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PREVIOUS_TRACK:
        {
            usbSendDefaultHidConsumerOscEvent(4 /* PREVIOUS TRACK */);
            return usb_device_class_status_success;
        }
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PLAY:
        {
            usbSendDefaultHidConsumerOocEvent(16, 1 /* PLAY on */);
            return usb_device_class_status_success;
        }
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_PAUSE:
        {
            usbSendDefaultHidConsumerOocEvent(32, 1 /* PAUSE on */);
            return usb_device_class_status_success;
        }
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_VOL_UP:
        {
            usbSendDefaultHidConsumerOscEvent(256 /* vol + */);
            return usb_device_class_status_success;
        }
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_VOL_DOWN:
        {
            usbSendDefaultHidConsumerOscEvent(512 /* vol - */);
            return usb_device_class_status_success;
        }
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_MUTE:
        {
            usbSendDefaultHidConsumerOocEvent(1024, 1 /* Mute on/off */);
            return usb_device_class_status_success;
        }
        
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_FFWD_ON:
        {
            usbSendDefaultHidConsumerOocEvent(64, 1 /* FFWD on */);
            return usb_device_class_status_success;
        }
        
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_REW_ON:
        {
            usbSendDefaultHidConsumerOocEvent(128, 1 /* RWD on */);
            return usb_device_class_status_success;
        }
        
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_FFWD_OFF:
        {
            usbSendDefaultHidConsumerOocEvent(64, 0 /* FFWD off */);
            return usb_device_class_status_success;
        }
        
        case USB_DEVICE_CLASS_EVENT_HID_CONSUMER_TRANSPORT_REW_OFF:
        {
            usbSendDefaultHidConsumerOocEvent(128, 0 /* RWD off */);
            return usb_device_class_status_success;
        }
        
        default:
        {
            break;
        }
    }
    return usb_device_class_status_invalid_param_value;
}


usb_device_class_status usbSendDefaultHidKeyboardEvent(usb_device_class_event event)
{
    switch (event)
    {
        case USB_DEVICE_CLASS_EVENT_HID_KEYBOARD_ALT_PGUP:
        {              
            usbSendDefaultHidKeyboardModifierEvent(4, 0x4b /* ALT, PGUP */);                
            return usb_device_class_status_success;
        }    
        case USB_DEVICE_CLASS_EVENT_HID_KEYBOARD_ALT_PGDN:
        {              
            usbSendDefaultHidKeyboardModifierEvent(4, 0x4e /* ALT, PGDN */);                
            return usb_device_class_status_success;
        }      
        case USB_DEVICE_CLASS_EVENT_HID_KEYBOARD_ALT_END:
        {              
            usbSendDefaultHidKeyboardModifierEvent(4, 0x4d /* ALT, END */);                
            return usb_device_class_status_success;
        }
        default:
        {
            break;
        }
    }
    return usb_device_class_status_invalid_param_value;
}


bool usbSendReportHidConsumerTransport(uint16 report_id, uint16 size_report, uint8 *report)
{
    Sink sink = StreamUsbEndPointSink(end_point_int_out);
    uint8 *data = NULL; 
    uint16 i = 0;    
    
    data = claimSink(sink, size_report + 1);
    
    if (data)
    {
        PRINT(("USB: Send Report with data "));           
            
        data[0] = (report_id | USB_REPORT_TYPE_INPUT ) & 0xff; /* report ID is first byte */
        
        for (i = 0; i < size_report; i++)
        {                
            data[i + 1] = report[i];
            PRINT(("%x ", data[i]));
        }
        PRINT(("%x\n", data[size_report])); 
          
        return SinkFlush(sink, size_report + 1);
    }
    
    return FALSE;   
}

#else /* !USB_DEVICE_CLASS_REMOVE_HID */
    static const int usb_device_class_hid_unused;
#endif /* USB_DEVICE_CLASS_REMOVE_HID */
