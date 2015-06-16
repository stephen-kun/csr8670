/***************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_debug.h
    
DESCRIPTION
    
*/

#ifndef _SINK_DEBUG_H_
#define _SINK_DEBUG_H_


#ifndef RELEASE_BUILD /*allows the release build to ensure all of the below are removed*/
    
    /*The individual configs*/
    
 
#ifndef DO_NOT_DOCUMENT

#endif 
 /*end of DO_NOT_DOCUMENT*/

    /*The global debug enable*/ 
    #define DEBUG_PRINT_ENABLEDx

    #ifdef DEBUG_PRINT_ENABLED
        #define DEBUG(x) {printf x;}

        /*The individual Debug enables*/
            /*The main system messages*/
        #define DEBUG_MAIN
            /* RSSI pairing */
        #define DEBUG_INQx
                /*The button manager */
        #define DEBUG_BUT_MANx
            /*The low level button parsing*/
        #define DEBUG_BUTTONSx
            /*The call manager*/
        #define DEBUG_CALL_MANx
            /*The multipoint manager*/
        #define DEBUG_MULTI_MANx
            /*sink_audio.c*/
        #define DEBUG_AUDIOx
         /* sink_slc.c */
        #define DEBUG_SLCx
        /* sink_devicemanager.c */
        #define DEBUG_DEVx
        /* sink_link_policy.c */
        #define DEBUG_LPx
            /*The config manager */
        #define DEBUG_CONFIGx
            /*The LED manager */
        #define DEBUG_LMx
            /*The Lower level LED drive */
        #define DEBUG_LEDSx
            /*The Lower level PIO drive*/
        #define DEBUG_PIOx
            /*The power Manager*/
        #define DEBUG_POWERx
            /*tones*/
        #define DEBUG_TONESx
            /*Volume*/
        #define DEBUG_VOLUMEx
            /*State manager*/
        #define DEBUG_STATESx
            /*authentication*/
        #define DEBUG_AUTHx
            /*dimming LEDs*/
        #define DEBUG_DIMx

        #define DEBUG_A2DPx

        #define DEBUG_PEERx
        #define DEBUG_PEER_SMx

        #define DEBUG_INITx

        #define DEBUG_AVRCPx

        #define DEBUG_AUDIO_PROMPTSx

        #define DEBUG_FILTER_ENABLEx

        #define DEBUG_CSR2CSRx      

        #define DEBUG_USBx

        #define DEBUG_MALLOCx 
            
        #define DEBUG_PBAPx

        #define DEBUG_MAPCx

        #define DEBUG_GAIAx
        
        #define DEBUG_SPEECH_RECx
        
        #define DEBUG_WIREDx
        
        #define DEBUG_AT_COMMANDSx
        
        #define DEBUG_GATTx
        
            /* BLE transport / messages debug */
        #define DEBUG_BLEx
        
        #define DEBUG_DUTx
        
            /* Device Id */
        #define DEBUG_DIx

        #define DEBUG_DISPLAYx
            
            /* Subwoofer debug */
        #define DEBUG_SWATx

        #define DEBUG_FMx
        
            /* Input manager debug */
        #define DEBUG_INPUT_MANAGERx
        
            /* BLE Remote Control debug */
        #define DEBUG_BLE_RCx
        
            /* IR Remote Control debug */
        #define DEBUG_IR_RCx
            
            /* Battery Reporting debug */
        #define DEBUG_BAT_REPx

    #else
        #define DEBUG(x) 
    #endif /*DEBUG_PRINT_ENABLED*/

        /* If you want to carry out cVc license key checking in Production test
           Then this needs to be enabled */
    #define CVC_PRODTESTx


#else /*RELEASE_BUILD*/    

/*used by the build script to include the debug but none of the individual debug components*/
    #ifdef DEBUG_BUILD 
        #define DEBUG(x) {printf x;}
    #else
        #define DEBUG(x) 
    #endif
        
#endif



#define INSTALL_PANIC_CHECK
#define NO_BOOST_CHARGE_TRAPS
#undef SINK_USB
#define HAVE_VBAT_SEL
#define HAVE_FULL_USB_CHARGER_DETECTION

#endif /*_SINK_DEBUG_H_*/

