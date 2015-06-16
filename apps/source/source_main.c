/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_a2dp.c

DESCRIPTION
    
*/


/* application header files */
#include "source_a2dp_msg_handler.h"
#include "source_app_msg_handler.h"
#include "source_audio.h"
#include "source_avrcp_msg_handler.h"
#include "source_codec_msg_handler.h"
#include "source_connection_msg_handler.h"
#include "source_debug.h"
#include "source_memory.h"
#include "source_private.h"
#include "source_states.h"
#include "source_usb.h"
#include "source_usb_msg_handler.h"
#include "source_volume.h"
#include "source_ps.h"
/* profile/library headers */
#include <a2dp.h>
#include <audio.h>
#include <codec.h>
#include <connection.h>
#include <usb_device_class.h>
/* VM headers */
#include <panic.h>
#include <string.h>


/* function for time critical functionality */
extern void _init(void);


/* application variables */
SOURCE_TASK_DATA_T *theSource;

        
/***************************************************************************
Functions
****************************************************************************
*/


/****************************************************************************
NAME    
    _init - Time critical initialisation
*/
void _init(void)
{
    theSource = memory_create(sizeof(SOURCE_TASK_DATA_T));
    
    if (theSource == NULL)
    {
        /* cannot create memory required to hold variables - check memory usage */
        Panic();
    }
      
    /* initialise the application variables */
    memset(theSource, 0, sizeof(SOURCE_TASK_DATA_T));
    
    /* allocate memory for PS configuration */
    theSource->ps_config = memory_create(sizeof(PS_CONFIG_T));
       
    if (theSource->ps_config == NULL)
    {
        /* cannot create memory required to hold variables - check memory usage */
        Panic();
    }
     
    /* initialise the PS variables */
    memset(theSource->ps_config, 0, sizeof(PS_CONFIG_T));
    
    /* Set task message handlers */
    theSource->codecTask.handler = codec_msg_handler;
    theSource->connectionTask.handler = connection_msg_handler;
    theSource->usbTask.handler = usb_msg_handler;
    theSource->app_data.appTask.handler = app_msg_handler;        
    theSource->audioTask.handler = audio_plugin_msg_handler;
    
    /* Set Config Set Version */
    ps_set_version();
    
    /* setup volume before USB is initialised as new volumes may be sent instantly over USB */
    volume_initialise();
    
    /* Time critical USB setup */
    usb_time_critical_init();   
}

      
/****************************************************************************
NAME    
    main - Initial function called when the application runs
*/
int main(void)
{    
    /* turn off charger LED indications */
    ChargerConfigure(CHARGER_SUPPRESS_LED0, TRUE);
    /* initialise state machine */
    states_set_state(SOURCE_STATE_INITIALISING);        
    
    MessageLoop();
    
    return 0;
}
