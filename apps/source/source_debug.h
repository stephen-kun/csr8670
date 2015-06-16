/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_debug.h

DESCRIPTION
    Controls debug output.
*/


#ifndef _SOURCE_DEBUG_H_
#define _SOURCE_DEBUG_H_


/* defines used to turn on debug output */
#define DEBUG_PRINT_ENABLEDx

#ifdef DEBUG_PRINT_ENABLED
    #include <stdio.h>
    #define DEBUG(x) {printf x;}
#else
    #define DEBUG(x)
#endif


/* defines used to display debug output in the source files */
#define DEBUG_A2DP
#define DEBUG_A2DP_MSG
#define DEBUG_AGHFP
#define DEBUG_AGHFP_MSG
#define DEBUG_APP_MSG
#define DEBUG_AUDIO
#define DEBUG_AVRCP
#define DEBUG_AVRCP_MSG
#define DEBUG_BUTTONS
#define DEBUG_CL_MSG
#define DEBUG_CODEC_MSG
#define DEBUG_CONNECTION_MGR
#define DEBUG_DEFAULTS
#define DEBUG_INIT
#define DEBUG_INQUIRY
#define DEBUG_LEDS
#define DEBUG_MEMORY
#define DEBUG_POWER
#define DEBUG_PS
#define DEBUG_SCAN
#define DEBUG_STATES
#define DEBUG_USB
#define DEBUG_USB_MSG
#define DEBUG_VOLUME


/* Display a Bluetooth address */
#define DEBUG_BDADDR(addr) DEBUG((" bdaddr [0x%x:0x%x:0x%lx]\n", addr.nap, addr.uap, addr.lap))


#endif /* _SOURCE_DEBUG_H_ */

