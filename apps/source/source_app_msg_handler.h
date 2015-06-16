/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_app_msg_handler.h

DESCRIPTION
    Application message handler
*/


#ifndef _SOURCE_APP_MSG_HANDLER_H_
#define _SOURCE_APP_MSG_HANDLER_H_


/* profile/library headers */
#include <csr_ag_audio_plugin.h>
/* VM headers */
#include <bdaddr.h>
#include <message.h>
#include <panic.h>


/* Application defined messages */
#define APP_INTERNAL_MESSAGE_BASE 0

typedef enum
{
    APP_INIT_CFM = APP_INTERNAL_MESSAGE_BASE,
    APP_CONNECT_SUCCESS_CFM,
    APP_CONNECT_FAIL_CFM,
    APP_DISCONNECT_IND,
    APP_CONNECT_REQ,
    APP_DISCONNECT_REQ,
    APP_DISCONNECT_SIGNALLING_REQ,
    APP_LINKLOSS_IND,
    APP_INQUIRY_STATE_TIMEOUT,
    APP_INQUIRY_IDLE_TIMEOUT,
    APP_INQUIRY_CONTINUE,
    APP_ENTER_PAIRING_STATE_FROM_IDLE,
    APP_ENTER_CONNECTABLE_STATE_FROM_IDLE,
    APP_USB_FFWD_RELEASE,
    APP_USB_REW_RELEASE,
    APP_AUDIO_START,
    APP_AUDIO_SUSPEND,
    APP_POWER_ON_DEVICE,
    APP_POWER_OFF_DEVICE,
    APP_USB_AUDIO_ACTIVE,
    APP_USB_AUDIO_INACTIVE,
    APP_STORE_DEVICE_ATTRIBUTES,
    APP_MIC_AUDIO_ACTIVE,
    APP_MIC_AUDIO_INACTIVE,
    APP_INTERNAL_MESSAGE_TOP
} AppMessageId;    


typedef struct
{
    uint16 warp[CSR_AG_AUDIO_WARP_NUMBER_VALUES];
} ATTRIBUTES_T;

typedef struct
{
    bool force_inquiry_mode;
} APP_CONNECT_REQ_T;

typedef struct
{
    bdaddr addr;
    ATTRIBUTES_T attributes;
} APP_STORE_DEVICE_ATTRIBUTES_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    app_msg_handler

DESCRIPTION
    Handles application messages.

*/
void app_msg_handler(Task task, MessageId id, Message message);


/****************************************************************************
NAME    
    app_power_device

DESCRIPTION
    Latches power on and removes power from the device.

*/
void app_power_device(bool enable);


#endif /* _SOURCE_APP_MSG_HANDLER_H_ */
