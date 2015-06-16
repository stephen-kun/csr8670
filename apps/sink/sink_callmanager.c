/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_callmanager.h      

DESCRIPTION
    This is the call manager for sink device
    

NOTES

*/
#include "sink_callmanager.h"
#include "sink_statemanager.h"
#include "sink_tones.h"
#include "sink_audio.h"
#include "sink_private.h"
#include "sink_configmanager.h"
#include "sink_slc.h"
#include "sink_audio_prompts.h"
#include "sink_multipoint.h"
#include "sink_speech_recognition.h"
#include "sink_config.h"

#include <ps.h>
#include <connection.h>
#include <hfp.h>
#include <stdlib.h>
#include <audio.h>
#include <string.h>
#include <sink.h>

#ifdef DEBUG_CALL_MAN
    #define CM_DEBUG(x) DEBUG(x)
#else
    #define CM_DEBUG(x) 
#endif

#define SIZE_CONFIG_PHONE_NUMBER 20
#define SIZE_PHONE_NUMBER       21

/****************************************************************************
NAME    
    sinkHandleRingInd
    
DESCRIPTION
    Received a RING indication from the AG.

RETURNS
    void
*/
void sinkHandleRingInd( const HFP_RING_IND_T * pInd )
{       
    /* check whether the ring ind needs to be shown as a call waiting beep
       for multipoint operation, if not multipoint function returns false */
    if(!MPCheckRingInd(pInd))
    {
        /*  Determine which AG has the outband ring (if applicable) and play
    		appropriate tone. */
#ifdef ENABLE_SPEECH_RECOGNITION
        if((!pInd->in_band)&&(!speechRecognitionIsEnabled()))
#else
        if(!pInd->in_band)           
#endif
        {
             /* determine whether this is AG1 or AG2 and play appropriate tone */
             if(pInd->priority == hfp_primary_link)
             {
            		CM_DEBUG(("CM: OutBandRing - AG1 play ring 1\n")) ;		
    				TonesPlayEvent(EventSysRingtone1);
             }
             /* this is AG2 so play ring tone for AG2 */
             else if(pInd->priority == hfp_secondary_link)
             {
            		CM_DEBUG(("CM: OutBandRing - AG2 play ring 2\n")) ;		
    				TonesPlayEvent(EventSysRingtone2);       
             }
        } 
        else 
        	CM_DEBUG(("CM: inBandRing or speech rec enabled - no tone played\n")) ;		
    }
}

/****************************************************************************
NAME    
    sinkAnswerOrRejectCall
    
DESCRIPTION
    Answer an incoming call from the device

RETURNS
    void
*/
void sinkAnswerOrRejectCall( bool Action )
{
    hfp_link_priority priority;
    
    /* if the SR plugin is running, disconnect it */
    MessageSend ( &theSink.task , EventSysSpeechRecognitionStop , 0 ) ;

    /* get profile if AG with incoming call */
    priority = HfpLinkPriorityFromCallState(hfp_call_state_incoming);

    CM_DEBUG(("CM: Answer Call on AG%x\n",priority)) ;

    /* if match found */
    if(priority)
    {
        /* answer call */
        HfpCallAnswerRequest(priority, Action);
        theSink.profile_data[PROFILE_INDEX(priority)].status.local_call_action = TRUE; 
    }
    /*terminate the ring tone*/
    ToneTerminate();
}


/****************************************************************************
NAME    
    sinkHangUpCall
    
DESCRIPTION
    Hang up the call from the device.

RETURNS
    void
*/
void sinkHangUpCall( void )
{
    /* Determine which is the current active call */  
    hfp_link_priority priority = hfp_invalid_link;
    hfp_call_state call_state;
    
    /* Get profile if AG with audio, also ensure AG is actually in a call, otherwise try other methods */
    if((theSink.routed_audio)&&(HfpLinkGetCallState(HfpLinkPriorityFromAudioSink(theSink.routed_audio), &call_state)&& (call_state)))    
        priority = HfpLinkPriorityFromAudioSink(theSink.routed_audio);
    
    /* No audio so use AG state */
    if(!priority)
        priority = HfpLinkPriorityFromCallState(hfp_call_state_active);

    /* No active call, check for an outgoing call to terminate */
    if(!priority)
        priority = HfpLinkPriorityFromCallState(hfp_call_state_outgoing);

    /* No active/outgoing calls, check for TWC state */
    if(!priority)
        priority = HfpLinkPriorityWithActiveCall(FALSE);

    /* no active calls but still a held call on the phone */
    if(!priority)
        priority = HfpLinkPriorityFromCallState(hfp_call_state_held_remaining); 
    
    /* If match found */
    if(priority && HfpLinkGetCallState(priority, &call_state))
    {
        switch(call_state)
        {
            case hfp_call_state_twc_incoming:
            case hfp_call_state_twc_outgoing:
            case hfp_call_state_held_active:
            case hfp_call_state_multiparty:
                CM_DEBUG(("CM: HangUp TWC active Call on AG%x\n",priority)) ;
                HfpCallHoldActionRequest(priority, hfp_chld_release_active_accept_other, 0);

            break;
            case hfp_call_state_held_remaining:
                CM_DEBUG(("CM: HangUp TWC held Call on AG%x\n",priority)) ;
                HfpCallHoldActionRequest(priority, hfp_chld_release_held_reject_waiting, 0);
            break;
            default:
                /* Terminate call using AT+CHUP */
                CM_DEBUG(("CM: HangUp Call on AG%x\n",priority)) ;
                HfpCallTerminateRequest(priority);
            break;
        }
    }
}


/****************************************************************************
NAME    
    sinkInitiateLNR
    
DESCRIPTION
    If HFP and connected - issues command
    If HFP and not connected - connects and issues if not in call
    If HSP sends button press

RETURNS
    void
*/
void sinkInitiateLNR ( hfp_link_priority priority )
{

    CM_DEBUG(("CM: LNR\n")) ;

    /* if device not connected to any AG initiate a connection */
    if (!stateManagerIsConnected() )
    {
#ifdef ENABLE_AVRCP       
        sinkAvrcpCheckManualConnectReset(NULL);
#endif        
        MessageSend ( &theSink.task , EventUsrEstablishSLC , 0 ) ;
        sinkQueueEvent(EventUsrLastNumberRedial) ;
    }
    /* have at least one connection */    
    else
    {
        uint8 Option = hfp_primary_link;
        
        CM_DEBUG(("CM: LNR Connected\n")) ;
   
        /* for multipoint use there are two options */
        if(theSink.MultipointEnable) 
        {
            /* these being to use separate LNR buttons, one for AG1 and one for AG2
               or use one LNR event and dial using the AG that last made an outgoing
               call */
            if(theSink.features.SeparateLNRButtons)
            {
                CM_DEBUG(("CM: LNR use separate LNR buttons\n")) ;
                Option = priority;
            }
            /* dial using AG that made last outgoing call */
            else
            {
                CM_DEBUG(("CM: LNR use last outgoing AG = %d\n",theSink.last_outgoing_ag)) ;
                Option = theSink.last_outgoing_ag;
            }
        }
        CM_DEBUG(("CM: LNR on AG %d\n",Option)) ;
        /* perform last number redial */        
        HfpDialLastNumberRequest(Option);
    }
}

/****************************************************************************
NAME    
    sinkInitiateVoiceDial
    
DESCRIPTION
    If HFP and connected - issues command
    If HFP and not connected - connects and issues if not in call
    If HSP sends button press

RETURNS
    void
*/
void sinkInitiateVoiceDial ( hfp_link_priority priority )
{
    CM_DEBUG(("CM: VD\n")) ;
	
    if (!stateManagerIsConnected() )
    {	
#ifdef ENABLE_AVRCP
        sinkAvrcpCheckManualConnectReset(NULL);
#endif        
        MessageSend ( &theSink.task , EventUsrEstablishSLC , 0 ) ;
        sinkQueueEvent( EventUsrInitateVoiceDial ) ;
        
        theSink.VoiceRecognitionIsActive = hfp_invalid_link ;
    }
    else
    {
        uint8 Option = hfp_primary_link;
    
        CM_DEBUG(("CM: VD Connected\n")) ;
        
        /* for multipoint use there are two options */
        if(theSink.MultipointEnable) 
        {
            /* these being to use separate VD buttons, one for AG1 and one for AG2
               or use one VD event and dial using the AG that last made an outgoing
               call */
            if(theSink.features.SeparateVDButtons)
            {
                Option = priority;
            }
            /* voice dial using AG that made last outgoing call */
            else
            {
                Option = theSink.last_outgoing_ag;
            }
        }             
        CM_DEBUG(("CM: VoiceDial on %d\n",Option)) ;
        HfpVoiceRecognitionEnableRequest(Option, TRUE);    
        theSink.VoiceRecognitionIsActive = Option;
    }    
}
/****************************************************************************
NAME    
    sinkCancelVoiceDial
    
DESCRIPTION
    cancels a voice dial request
   
RETURNS
    void
*/
void sinkCancelVoiceDial ( hfp_link_priority priority )
{
    uint8 Option = hfp_primary_link;
    
    CM_DEBUG(("CM: VD Cancelled")) ;
        
    /* for multipoint use there are two options */
    if(theSink.MultipointEnable) 
    {
        /* these being to use separate VD buttons, one for AG1 and one for AG2
           or use one VD event and dial using the AG that last made an outgoing
           call */
        if(theSink.features.SeparateVDButtons)
        {
            Option = priority;
        }
        /* voice dial using AG that made last outgoing call */
        else
        {
            Option = theSink.last_outgoing_ag;
        }
    }    

    /*if we believe voice dial is currently active*/
    if ( theSink.VoiceRecognitionIsActive)
    {
        HfpVoiceRecognitionEnableRequest(Option, FALSE);                    
        theSink.VoiceRecognitionIsActive = hfp_invalid_link;
    }
}

/****************************************************************************
NAME    
    sinkQueueEvent
    
DESCRIPTION
    Queues an event to be sent once the device is connected

RETURNS
    void
*/
void sinkQueueEvent ( sinkEvents_t pEvent )
{
    CM_DEBUG(("CM: QQ Ev[%x]\n", pEvent)) ;
    theSink.gEventQueuedOnConnection = (pEvent - EVENTS_MESSAGE_BASE);
}

/****************************************************************************
NAME    
    sinkRecallQueuedEvent
    
DESCRIPTION
    Checks to see if an event was Queued and issues it

RETURNS
    void
*/
void sinkRecallQueuedEvent ( void )
{
    /*this is currently only applicable to  LNR and voice Dial but does not care */
    if ((theSink.gEventQueuedOnConnection != (EventInvalid - EVENTS_MESSAGE_BASE)))
    {
        switch (stateManagerGetState() )
        {
            case deviceIncomingCallEstablish:
            case deviceOutgoingCallEstablish:
            case deviceActiveCallSCO:            
            case deviceActiveCallNoSCO:       
            case deviceThreeWayCallWaiting:
            case deviceThreeWayCallOnHold:
            case deviceThreeWayMulticall:
                /* Do Nothing Message Gets ignored*/
            break ;
            default:
               /* delay sending of queued message by 1 second as some phones are ignoring the AT command when
                  using native firmware as the connection time is much quicker using that firmware */             
               MessageSendLater ( &theSink.task , (theSink.gEventQueuedOnConnection + EVENTS_MESSAGE_BASE), 0 , 1500) ; 
            break;
        }
    }    
    
    /*reset the queued event*/
	sinkClearQueueudEvent(); 
}

/****************************************************************************
NAME    
    sinkClearQueueudEvent
    
DESCRIPTION
    Clears the QUEUE - used on failure to connect / power on / off etc

RETURNS
    void
*/
void sinkClearQueueudEvent ( void )
{
    /*this resets the queue - on a conenction fail / power off etc*/
    sinkQueueEvent(EventInvalid) ;
}


/****************************************************************************
NAME    
    sinkUpdateStoredNumber
    
DESCRIPTION
	Request a number to store from the primary AG
    
RETURNS
    void
*/
void sinkUpdateStoredNumber (void)
{
    Sink sink;
    
    /* validate HFP available for use, i.e. AG connected */
    if((HfpLinkGetSlcSink(hfp_primary_link, &sink))&&SinkIsValid(sink))
    {
        /* Request user select a number on the AG */
        HfpVoiceTagNumberRequest(hfp_primary_link);
    }
    else
    {
        /* Connect and queue request */
#ifdef ENABLE_AVRCP
        sinkAvrcpCheckManualConnectReset(NULL);
#endif        
        MessageSend ( &theSink.task , EventUsrEstablishSLC , 0 ) ;
        sinkQueueEvent( EventUsrUpdateStoredNumber ) ;
    }
}


/****************************************************************************
NAME    
    sinkWriteStoredNumber
    
DESCRIPTION
	Store number obtained via HfpRequestNumberForVoiceTag in 
    CONFIG_PHONE_NUMBER
    
RETURNS
    void
*/
void sinkWriteStoredNumber ( HFP_VOICE_TAG_NUMBER_IND_T* ind )
{
    /* validate length of number returned */
    if((ind->size_phone_number)&&(ind->size_phone_number<SIZE_CONFIG_PHONE_NUMBER))
    {
        uint16 phone_number_key[SIZE_CONFIG_PHONE_NUMBER];
        
        CM_DEBUG(("Store Number "));
        
        /* Make sure the phone number key is all zero to start */
        memset(phone_number_key, 0, SIZE_CONFIG_PHONE_NUMBER*sizeof(uint16));   
        
        /* Write phone number into key array */
        memmove(phone_number_key,ind->phone_number,ind->size_phone_number);        
        
        /* Write to PS */
        ConfigStore(CONFIG_PHONE_NUMBER, &phone_number_key, ind->size_phone_number);
    }
}


/****************************************************************************
NAME    
    sinkDialStoredNumber
    
DESCRIPTION
	Dials a number stored in CONFIG_PHONE_NUMBER
    If HFP and connected - issues command
    If HFP and not connected - connects and issues if not in call
    If HSP sends button press


RETURNS
    void
*/
void sinkDialStoredNumber ( void )
{	
    uint16 ret_len;
	Sink   sink;
    uint16 phone_number_key[SIZE_CONFIG_PHONE_NUMBER];
    
	CM_DEBUG(("sinkDialStoredNumber\n")) ;
    
    if ((ret_len = ConfigRetrieve(CONFIG_PHONE_NUMBER, phone_number_key, SIZE_CONFIG_PHONE_NUMBER )))
	{        
        if((HfpLinkGetSlcSink(hfp_primary_link, &sink)) && SinkIsValid(sink))
        {
            /* Send the dial request now */
            CM_DEBUG(("CM:Dial Stored Number (Connected) len=%x\n",ret_len)) ;  
            HfpDialNumberRequest(hfp_primary_link, ret_len, (uint8 *)&phone_number_key[0]);  
        }
        else
        {
            /* Not connected, connect and queue the dial request */
#ifdef ENABLE_AVRCP
            sinkAvrcpCheckManualConnectReset(NULL);
#endif            
            MessageSend ( &theSink.task , EventUsrEstablishSLC , 0 ) ;
            sinkQueueEvent( EventUsrDialStoredNumber ) ;
        }
    }
    else
	{
        /*The PSKEY could not be read*/
        MessageSend(&theSink.task, EventUsrUpdateStoredNumber, 0);
    }
}

/****************************************************************************
NAME    
    sinkPlaceIncomingCallOnHold
    
DESCRIPTION
	looks for an incoming call and performs the twc hold incoming call function

RETURNS
    void
*/
void sinkPlaceIncomingCallOnHold(void)
{
     hfp_call_state CallState;
     /* find incoming call to hold */
     if((HfpLinkGetCallState(hfp_primary_link, &CallState))&&
        (CallState == hfp_call_state_incoming))
     {
         CM_DEBUG(("MAIN: Hold incoming Call on AG1\n")) ;
         HfpResponseHoldActionRequest(hfp_primary_link, hfp_hold_incoming_call);
     }
     else if((HfpLinkGetCallState(hfp_secondary_link, &CallState))&&
             (CallState == hfp_call_state_incoming))
     {
         CM_DEBUG(("MAIN: Hold incoming Call on AG2\n")) ;
         HfpResponseHoldActionRequest(hfp_secondary_link, hfp_hold_incoming_call);                
     }
 }

/****************************************************************************
NAME    
    sinkAcceptHeldIncomingCall
    
DESCRIPTION
	looks for a held incoming call and performs the twc accept held incoming
    call function

RETURNS
    void
*/
void sinkAcceptHeldIncomingCall(void)
 {
     hfp_call_state CallState;
     /* find incoming held call */
     if((HfpLinkGetCallState(hfp_primary_link, &CallState))&&
        (CallState == hfp_call_state_incoming_held))
     {
         CM_DEBUG(("MAIN: Hold incoming Call on AG1\n")) ;
         HfpResponseHoldActionRequest(hfp_primary_link, hfp_accept_held_incoming_call);
     }
     else if((HfpLinkGetCallState(hfp_secondary_link, &CallState))&&
             (CallState == hfp_call_state_incoming_held))
     {
         CM_DEBUG(("MAIN: Hold incoming Call on AG2\n")) ;
         HfpResponseHoldActionRequest(hfp_secondary_link, hfp_accept_held_incoming_call);                
     }
 }
 
/****************************************************************************
NAME    
    sinkRejectHeldIncomingCall
    
DESCRIPTION
	looks for a held incoming call and performs the twc reject held incoming
    call function

RETURNS
    void
*/
void sinkRejectHeldIncomingCall(void)
 {
     hfp_call_state CallState;
     /* find incoming held call */
     if((HfpLinkGetCallState(hfp_primary_link, &CallState))&&
        (CallState == hfp_call_state_incoming_held))
     {
         CM_DEBUG(("MAIN: Hold incoming Call on AG1\n")) ;
         HfpResponseHoldActionRequest(hfp_primary_link, hfp_reject_held_incoming_call);
     }
     else if((HfpLinkGetCallState(hfp_secondary_link, &CallState))&&
             (CallState == hfp_call_state_incoming_held))
     {
         CM_DEBUG(("MAIN: Hold incoming Call on AG2\n")) ;
         HfpResponseHoldActionRequest(hfp_secondary_link, hfp_reject_held_incoming_call);                
     }
 }
