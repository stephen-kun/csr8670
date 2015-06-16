/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014
Part of ADK 3.5

FILE NAME
    main.c
    
DESCRIPTION
	Simple Audio AG for DEV-PC 1395 JJK
        
    This application runs by default on a DEV_PC_1395 pcb board
    with a BC4-Audio-Flash (Jumping Jack) chip.
    
    The addition of the "DEV_PC_1645" in the project properties
    defines will allow the app to run on a DEV_PC_1645 board using a 
    BC5-MM part. You will also need to change the firmware from
    compact->unified
    
    ---------------------------------------------------------------------------------------------
    The operation is as follows,
    
    PWR button:
        The application will connect / discconnect a HFP connection 
        with the device whose Bluettoth address is contained in 
        PSKEY_USR_10 in the format 0002 005b 0000 9922
                                    nap  uap   lap 
        
    
    MFB Button:
        Once connected, the application will connect/disconenct an
        audio connction. The parameters used fro this connection are 
        contained in PSKEY_USR_11 with the format
        02bf 0000 1f40 0010 0000 0002
        pkts bandwidth  lat  vce retx
        
        pkts - packets supported
            (1<<9) - 3EV5 - 1 to DISable
            (1<<8) - 2EV5 - 1 to DISable
            (1<<7) - 3EV3 - 1 to DISable
            (1<<6) - 2EV3 - 1 to DISable
            (1<<5) - EV3  - 1 to enable
            (1<<4) - EV2  - 1 to enable
            (1<<3) - EV1  - 1 to enable
            (1<<2) - HV3  - 1 to enable
            (1<<1) - HV2  - 1 to enable
            (1<<0) - HV1  - 1 to enable
            
        bandwidth - set to 8000d = 0x0000 0x1f40
        
        lat - latency 
            0x0010 - will allow 60 byte 2EV3 packets
            0x0007 - HFP 1.5 S1 parameters (30 byte 2EV3 packets)
        
        vce - voice settings
        
        retx - retransmission effort
            Enumeration values: 

           0x0000 sync_retx_disabled        No retransmissions. 
           0x0001 sync_retx_power_usage     At least one retransmission, optimise for power consumption. 
           0x0002 sync_retx_link_quality    At least one retransmission, optimise for link quality. 
           0x00FF sync_retx_dont_care       Don't care.
                        
    
    VOL+  and VOL -    
        control volume operation of local AG
       
    ---------------------------------------------------------------------------------------------    
    PIO configuration
    
    DEV_PC_1395
        MFB     MFB - connect / disconnect HFP
        FCN     FCN - connect disconnect audio 
        VOL +   VOL UP
        VOL -   VOL DOWN
        
    DEV_PC_1645
        AUX_2       MFB - connect / disconnect HFP
        BLUEMEDIA   FCN - connect disconnect audio   
        VOL +       VOL UP
        VOL -       VOL DOWN
        
    ---------------------------------------------------------------------------------------------
    CONFIGURATION
    
    DEBUG_PRINT_ENABLED
        Debug output can be enabled by including DEBUG_PRINT_ENABLED in the project properties -> defines
    DEV_PC_1645
        Allow app to run on a 1645 board can be enabled by including DEV_PC_1645 in the project properties -> defines
     
    ---------------------------------------------------------------------------------------------
    Typical PSKEYS

	
	//PSKEY_USR_9 - which audio codec to use 1=cvsd, 2,4 = auristream
	&0293 = 0001		
    
    // PSKEY_USR10 - Connect back to this device   
    &0294 = 0002 005b 0000 9922
    
    // PSKEY_USR11 - Use these audio parameters for a cvsd connection
    &0295 = 02bf 0000 1f40 0010 0000 0002 
	
	// PSKEY_USR12 - Use these audio parameters for an auristream connection
    &0295 = 02bf 0000 0fa0 0010 0063 0002 
		
    // PSKEY_LOCAL_SUPPORTED_FEATURES
    &00ef = fefc 800f e80b 0000
    
*/

#ifdef DEV_PC_1645
    #define CHIPBASE_BC5
#endif
#ifdef DEV_PC_1854
    #define CHIPBASE_BC5
#endif
		

#include <aghfp.h>
#include <message.h>
#include <vm.h>
#include <print.h>
#include <panic.h>
#include <stdlib.h>
#include <connection.h>
#include <ps.h>
#include <codec.h>
#include <audio.h>
#include <pio.h>
#include <psu.h>
#include <charger.h>
#include <micbias.h>


#include <csr_cvc_common_plugin.h>
#include <csr_common_example_plugin.h>

#include <charger.h>
#include "leds.h"

#include "simple_ag_buttons.h"

#include <app/bluestack/types.h>
#include <app/bluestack/bluetooth.h>
#include <app/bluestack/hci.h>
#include <app/bluestack/dm_prim.h>



/*good_tone*/
static const ringtone_note good_tone[] =
{
    RINGTONE_TEMPO(1000), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(G6 , SEMIBREVE),

    RINGTONE_NOTE(REST , HEMIDEMISEMIQUAVER),
    RINGTONE_END
};

static const ringtone_note bad_tone[] =
{
    RINGTONE_TEMPO(1000), RINGTONE_VOLUME(64), RINGTONE_TIMBRE(sine),
    
    RINGTONE_NOTE(D5 , SEMIBREVE),

    RINGTONE_NOTE(REST , HEMIDEMISEMIQUAVER),
    RINGTONE_END
};
/* User PS Key used to hold the servers bluetooth address */

#define PSKEY_AUDIO_CODEC 9
#define PSKEY_BD_ADDR 10
#define PSKEY_CVSD_PARAMS 11
#define PSKEY_AURISTREAM_PARAMS 12
#define PS_AV_SSR_PARAMS        (40)


/* User PS Key sizes */
#define PS_AV_SSR_PARAMS_SIZE   (sizeof(uint16)*6)



#define POWER_HOLD          (1<<9)

#define AUDIO_AMP_LINE (1<<4)

/* Enumeration providing symbolic references to the IDs in the AT+CSRFN and +CSRFN AT commands. */
typedef enum
{
	csr2csr_callername	= 1,
	csr2csr_raw_text,
	csr2csr_sms_ind,
	csr2csr_batt_level,
	csr2csr_power_source,
	csr2csr_codecs,
	csr2csr_codec_bandwidth
} csr2csr_indicator;

typedef enum 
{
	audio_codec_cvsd 				= 0,
	audio_codec_wbs_sbc 			= 1,
	audio_codec_wbs_amr 			= 2,
	audio_codec_wbs_evrc 			= 3,
	audio_codec_auristream_2_bit_8k,
	audio_codec_auristream_4_bit_8k,
	audio_codec_auristream_2_bit_16k,
	audio_codec_auristream_4_bit_16k
} audio_codec_type ;

typedef enum
{
	auristream_mask_cvsd				= (1 << 0),
	auristream_mask_auristream_2_bit	= (1 << 1),
	auristream_mask_auristream_4_bit	= (1 << 2)
} auristream_codec_masks;

typedef enum
{
	auristream_bw_mask_8k	= (1 << 0),
	auristream_bw_mask_16k	= (1 << 1)
} auristream_bw_masks;

typedef struct 
{
/*	uint16 packets ;
	aghfpAudioParams_params hfpAudioParams ;	
    */
    
    uint16 				syncPktTypes ;
	aghfp_audio_params 	hfpAudioParams;
	bool 				audioUseDefaults;
} audio_params_t ;

/** Structure for defining SSR parameters. These reflect the parameters in the HCI_Sniff_Subrating message. */
typedef struct
{
    uint16          max_remote_latency;
    uint16          min_remote_timeout;
    uint16          min_local_timeout;
} ssr_params;

/** Structure for defining seperate SSR parameters for SLC and SCO links. */
typedef struct
{
    ssr_params      slc_params;
    ssr_params      sco_params;
} subrate_data;
	
typedef struct 
{
    TaskData task;    
	PioState pio_state;
	AGHFP * aghfp;
	Sink audio_sink;
	
	bdaddr bd_addr ;
	
    Task codec_task ;
	uint16 volume ;
	
    /* Audio and SLC connection status */
	bool connecting_slc;
	bool audio ;
	bool connected ;
    
    audio_params_t 	audio_params ;
	
    /*not needed ?*/
	audio_params_t audio_cvsd_params ;
	audio_params_t audio_auristream_params ;
	
	/* The RFCOMM sink for the SLC connection */
    Sink            rfcomm_sink;
	/** Parameters for sniff subrating for SLC and SCO links. */
    subrate_data    ssr_data;
    
	/* The audio codec to use */
	audio_codec_type	audio_codec;

	/* Bitmap of the HF's supported CSR codecs. */
	unsigned int		hf_csr_codecs;
	/* Bitmap of the HF's supported CSR codec bandwidths. */
	unsigned int		hf_csr_codec_bandwidths;
	
	/* The audio codec to negotiate */
	audio_codec_type	codec_to_negotiate;
    
    	/* The bandwidth to negotiate in the case of a CSR CODEC (provided the HF supports bandwidth negotiation). */
	auristream_bw_masks	csr_codec_bandwidth_to_negotiate;

	/* The type of negotiation to employ for the codec_to_negotiate. */
	aghfp_codec_negotiation_type negotiation_type;
    
    	/* Set if the AG to capable of negotiating codecs using the CSR method. */
	unsigned int	csr_codec_negotiation_capable:1;
	unsigned int	codec_negotiated:1;
	unsigned int	start_audio_after_codec_negotiation:1;
	unsigned int	hf_supports_csr_bw_negotiation:1;
    unsigned int    hf_supports_csr_hf_initiated_codec_negotiation:1;
    unsigned int    ag_initiated_csr_codec_negotiation:1;
    unsigned int    ag_initiated_at_csrfn_resolved:1;
	
	
} SIMPLE_T ;

static SIMPLE_T SIMPLE ;

/* This is used during CSR2CSR CODEC negotiation. The HF MAY specify a bandwidth
   value, if so it will be a bitmap which a single bit set determining the requested
   bandwidth, or zero if the HF is rejecting a bandwidth request from the AG. This define
   allows the absence of the bandwidth parameter to be determined. Since valid values
   are only zero or one bit set, this value represents an invalid option and can be used
   to detect that the bandwidth option was never specified. */
#define NO_BANDWIDTH_SPECIFIED				(0xffff)

#define AG_CSR_SUPPORTED_FEATURES		(auristream_mask_cvsd | auristream_mask_auristream_2_bit | auristream_mask_auristream_4_bit)
#define AG_CSR_SUPPORTED_FEATURES_BW	(auristream_bw_mask_8k | auristream_bw_mask_16k)

/*! @brief Convert from a global app level codec enumeration (audio_codec_type) to a CSR specific bitmap (auristream_codec_masks).

	@param codecIn		An 'audio_codec_type' describing a chosen codec
	@param codecOut		Pointer to a variable to store the CSR bitmap.

	This function returns true if codecIn defines a CSR codec. Returns false otherwise.

*/
bool globalCodecEnumToCsrBitmap(audio_codec_type codecIn, auristream_codec_masks *codecOut);

/*! @brief Convert from an AGHFP WBS codec (aghfp_wbs_codec) to a global app level codec enumeration (audio_codec_type) .

	@param codecIn		An 'aghfp_wbs_codec' describing a chosen codec
	@param codecOut		Pointer to a variable to store the global app level codec enumeration value.

	This function returns true if codecIn defines an AGHFP WBS codec. Returns false otherwise.

*/
bool wbsEnumToGlobalCodecEnum(aghfp_wbs_codec codecIn, audio_codec_type *codecOut);


/*
	Process the information contained in the AT+CSRFN command for an HF initiated CSR CODEC negotiation.
*/
static bool csr2csrHandleFeatureNegotiationHfInitiated(AGHFP *aghfp, uint16 num_csr_features, uint16 codec, uint16 bandwidth, audio_codec_type	*audio_codec_selected)
{
	bool	rtnVal = FALSE;
	auristream_codec_masks	codec_to_negotiate_as_csr_bitmap;
	

	/* Sanity check that we have something useful. */
	if((codec != 0) && (globalCodecEnumToCsrBitmap(SIMPLE.codec_to_negotiate, &codec_to_negotiate_as_csr_bitmap) != FALSE))
	{
		if(codec != codec_to_negotiate_as_csr_bitmap)
		{
			PRINT(("CSR2CSR: Rejecting HF's codec (AT+CSRFN)\n"));

			aghfpFeatureNegotiate(aghfp, num_csr_features, csr2csr_codecs, 0, csr2csr_codec_bandwidth, bandwidth, FALSE);

			AghfpSendError(aghfp);
		}
		else
		{
			/* Codec value is ok. */
		
			if((bandwidth != NO_BANDWIDTH_SPECIFIED) && (bandwidth != SIMPLE.csr_codec_bandwidth_to_negotiate))
			{
				PRINT(("CSR2CSR: Rejecting AG's choice of bandwidth (AT+CSRFN)\n"));

				aghfpFeatureNegotiate(aghfp, num_csr_features, csr2csr_codecs, codec, csr2csr_codec_bandwidth, 0, FALSE);

				AghfpSendError(aghfp);
			}
			else
			{
				/* The codec value will be in the form of a particular bit set in the
				   value for the message, e.g. 1, 2, 4, 8, etc. To save on space in globals
				   this values is stored as part of an enumerated list. The following switch statement
				   converts to the enumerated value. */
				switch(codec)
				{
					case(auristream_mask_cvsd):
						*audio_codec_selected = audio_codec_cvsd;
						rtnVal = TRUE;
						break;
					case(auristream_mask_auristream_2_bit):
						switch(bandwidth)
						{
							case(auristream_bw_mask_8k):
								*audio_codec_selected = audio_codec_auristream_2_bit_8k;
								break;
							case(auristream_bw_mask_16k):
								*audio_codec_selected = audio_codec_auristream_2_bit_16k;
								break;
							default:
								/* Default to 16k if bandwidth not specified in the AT command. */
								*audio_codec_selected = audio_codec_auristream_2_bit_16k;
								break;
						}

						rtnVal = TRUE;
						break;
					case(auristream_mask_auristream_4_bit):
						switch(bandwidth)
						{
							case(auristream_bw_mask_8k):
								*audio_codec_selected = audio_codec_auristream_4_bit_8k;
								break;
							case(auristream_bw_mask_16k):
								*audio_codec_selected = audio_codec_auristream_4_bit_16k;
								break;
							default:
								/* Default to 16k if bandwidth not specified in the AT command. */
								*audio_codec_selected = audio_codec_auristream_4_bit_16k;
								break;
						}

						rtnVal = TRUE;
						break;
					default: /* Should really get here. */
						break;
			    }

				/* Issue +CSRSF response if ok to do so. */
				if(rtnVal == TRUE)
				{
					aghfpFeatureNegotiate(aghfp, num_csr_features, 6, codec, 7, bandwidth, FALSE);
					AghfpSendOk(aghfp);
				}		
		    }
		}
	}

	return(rtnVal);
}

/*
	Process the information contained in the AT+CSRFN command for an AG initiated CSR CODEC negotiation.
*/
static bool csr2csrHandleFeatureNegotiationAgInitiated(AGHFP *aghfp, uint16 num_csr_features, uint16 codec, uint16 bandwidth, audio_codec_type audio_codec_requested)
{
	bool	rtnVal = FALSE;

	if((codec == 0) || (bandwidth == 0))
	{
		/* The HF doesn't like something. Try another negotiation.
		   This code merely sends what has already been conifgured. HF rejection of AG paramters is achieved by hacking the
		   AG code to send a known unsupported CODEC on its first attempt. This code will then sets things straight
		   and a successful CODEC connection should be achieved. */
		auristream_codec_masks	codec;

		globalCodecEnumToCsrBitmap(SIMPLE.codec_to_negotiate, &codec);
		aghfpFeatureNegotiate(aghfp, (SIMPLE.hf_supports_csr_bw_negotiation?2:1), 6, codec, 7, SIMPLE.csr_codec_bandwidth_to_negotiate, TRUE);
	}
	else
	{
		/* Check that the HF agrees with the choice of CODEC. */
		/* Note that if the bandwidth parameter is not present assume 8k for CVSD and 16k for Auristream. */
		switch(audio_codec_requested)
		{
			case(audio_codec_cvsd):
				if((codec == auristream_mask_cvsd) &&
					   ((bandwidth == auristream_bw_mask_8k) || (bandwidth == NO_BANDWIDTH_SPECIFIED))) rtnVal = TRUE;
				break;
			case(audio_codec_auristream_2_bit_8k):
					if((codec == auristream_mask_auristream_2_bit) &&
					   ((bandwidth == auristream_bw_mask_8k) || (bandwidth == NO_BANDWIDTH_SPECIFIED))) rtnVal = TRUE;
				break;
			case(audio_codec_auristream_2_bit_16k):
				if((codec == auristream_mask_auristream_2_bit) &&
					   ((bandwidth == auristream_bw_mask_16k) || (bandwidth == NO_BANDWIDTH_SPECIFIED))) rtnVal = TRUE;
				break;
			case(audio_codec_auristream_4_bit_8k):
					if((codec == auristream_mask_auristream_4_bit) &&
					   ((bandwidth == auristream_bw_mask_8k) || (bandwidth == NO_BANDWIDTH_SPECIFIED))) rtnVal = TRUE;
				break;
			case(audio_codec_auristream_4_bit_16k):
				if((codec == auristream_mask_auristream_4_bit) &&
					   ((bandwidth == auristream_bw_mask_16k) || (bandwidth == NO_BANDWIDTH_SPECIFIED))) rtnVal = TRUE;
				break;
			default:
				break;
		}

		if(rtnVal == TRUE)
		{
			AghfpSendOk(aghfp);
		}
		else
		{

			/* Cancel this AG initiated CODEC negotation in favour of the HF's request.
			   The HF should send a fresh request. */
			SIMPLE.ag_initiated_csr_codec_negotiation = FALSE;
			/* Negotiation paths possibly crossed over with AG. Try the negotation again from the start. */
			/* Just send an ERROR and wait for the HF to initiate another CODEC negotiation exchange. */
			AghfpSendError(aghfp);
		}

	}

	return(rtnVal);
}


static void read_config ( void )
{
	uint16 temp[8] = {0,0,0,0,0,0,0,0};
	uint16 len;
    AudioPluginFeatures features;

    /* determine additional features applicable for this audio plugin */
    features.stereo = FALSE;
    features.use_i2s_output = FALSE;
	

		/* Set the bluetooth address of the server */
    len = PsRetrieve(PSKEY_BD_ADDR,(void*)&temp[0],4);
	if (len>0)
	{
    	SIMPLE.bd_addr.nap = temp[0];
        SIMPLE.bd_addr.uap = (uint8)temp[1];
	    SIMPLE.bd_addr.lap = (uint32)temp[2]<<16 | (uint32)temp[3];
		PRINT(("BDADDR [%x][%x][%lx]\n" , SIMPLE.bd_addr.nap ,SIMPLE.bd_addr.uap , SIMPLE.bd_addr.lap )) ;/*temp[3] , temp[2]  )) ;											*/
		
	}
    else
	{ /*	 Bluetooth address not defined, use the default */
    	PRINT(("No Bluetooth Address Specified\n"));
		
    	Panic();
	}

	
		
		/* Get teh audio params to be used */
    len = PsRetrieve(PSKEY_CVSD_PARAMS , (void*)&SIMPLE.audio_cvsd_params , 6 );
	if (len>0)
	{
		PRINT(("AUDIO_PARAMS [%x][%x]\n" , SIMPLE.audio_cvsd_params.syncPktTypes , SIMPLE.audio_cvsd_params.hfpAudioParams.max_latency )) ;
		
		AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
	}
    else
	{
		/*Use Defaults*/
		PRINT(("AUDIO_PARAMS NONE FOUND !!\n")) ;
		
		SIMPLE.audio_cvsd_params.syncPktTypes                  = 0x003F ;
		SIMPLE.audio_cvsd_params.hfpAudioParams.bandwidth      = 8000 ;
		SIMPLE.audio_cvsd_params.hfpAudioParams.max_latency    = 16 ;
		SIMPLE.audio_cvsd_params.hfpAudioParams.voice_settings = 0 ;
		SIMPLE.audio_cvsd_params.hfpAudioParams.retx_effort      = 2 ;	
		
		AudioPlayTone( bad_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
		
	}
		
	
	len = PsRetrieve(PSKEY_AUDIO_CODEC , (void*)&SIMPLE.codec_to_negotiate , 1 )  ;
	if (len>0)
	{
		PRINT(("AUDIO_CODEC TO NEGOTIATE [%d]\n" , (int) SIMPLE.codec_to_negotiate ));
		AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
	}
	else
	{
		SIMPLE.codec_to_negotiate = audio_codec_cvsd ;
		AudioPlayTone( bad_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;		
		PRINT(("AUDIO_CODEC PSREAD FAILED \n")) ;
	}
	
			/* Get teh audio params to be used */
    len = PsRetrieve(PSKEY_AURISTREAM_PARAMS , (void*)&SIMPLE.audio_auristream_params , 6 );
	if (len>0)
	{
		PRINT(("AUDIO_PARAMS [%x][%d]\n" , (int)SIMPLE.audio_auristream_params.syncPktTypes , (int)SIMPLE.audio_auristream_params.hfpAudioParams.bandwidth )) ;
		
		AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
	}
    else
	{
		/*Use Defaults*/
		PRINT(("AUDIO_PARAMS NONE FOUND !!\n")) ;
		
		SIMPLE.audio_auristream_params.syncPktTypes                  = 0x003F ;
		SIMPLE.audio_auristream_params.hfpAudioParams.bandwidth      = 4000 ;
		SIMPLE.audio_auristream_params.hfpAudioParams.max_latency    = 16 ;
		SIMPLE.audio_auristream_params.hfpAudioParams.voice_settings = 0x63 ;
		SIMPLE.audio_auristream_params.hfpAudioParams.retx_effort      = 2 ;	
		
		AudioPlayTone( bad_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
		
	}
	
	SIMPLE.audio_codec = audio_codec_cvsd ;
    
        /* Get the SSR params from the PS */
    if(!PsRetrieve(PS_AV_SSR_PARAMS, &SIMPLE.ssr_data, PS_AV_SSR_PARAMS_SIZE))
    {
        /* Failed to get SSR settings so default to zero (No SSR) */
        SIMPLE.ssr_data.slc_params.max_remote_latency = 0;
        SIMPLE.ssr_data.slc_params.min_remote_timeout = 0;
        SIMPLE.ssr_data.slc_params.min_local_timeout = 0;
        SIMPLE.ssr_data.sco_params.max_remote_latency = 0;
        SIMPLE.ssr_data.sco_params.min_remote_timeout = 0;
        SIMPLE.ssr_data.sco_params.min_local_timeout = 0;
    }
		
}

/*****************************************************************************/
bool wbsEnumToGlobalCodecEnum(aghfp_wbs_codec codecIn, audio_codec_type *codecOut)
{
	bool rtn_value = TRUE;

	/* Translate from WBS module codec type to Headset codec type */
	switch(codecIn)
	{
		case(aghfp_wbs_codec_cvsd):
			*codecOut = audio_codec_cvsd;
			break;
		case(aghfp_wbs_codec_sbc):
			*codecOut = audio_codec_wbs_sbc;
			break;
		default:
			rtn_value = FALSE;
			break;
	}
	
	return(rtn_value);
}

/*****************************************************************************/
bool globalCodecEnumToCsrBitmap(audio_codec_type codecIn, auristream_codec_masks *codecOut)
{
	uint16 rtnValue = TRUE;

	switch(codecIn)
	{
		case(audio_codec_cvsd):
			*codecOut = auristream_mask_cvsd;
			break;
		case(audio_codec_auristream_2_bit_8k):
		case(audio_codec_auristream_2_bit_16k):
			*codecOut = auristream_mask_auristream_2_bit;
			break;
		case(audio_codec_auristream_4_bit_8k):
		case(audio_codec_auristream_4_bit_16k):
			*codecOut = auristream_mask_auristream_4_bit;
			break;
		default:
			*codecOut = auristream_mask_cvsd;
			rtnValue = FALSE;
			break;
	}

	return(rtnValue);
}

static void profile_handler(Task task, MessageId id, Message message)
{
    
    switch(id)
    {
        /* Connection Manager Messages */
    case CL_INIT_CFM:
        {
            CL_INIT_CFM_T *msg = (CL_INIT_CFM_T*)message;
            PRINT(("CL_INIT_CFM\n"));
            if (msg->status == success)
            {
                CsrInternalCodecTaskData *codec = PanicUnlessMalloc(sizeof(CsrInternalCodecTaskData));
                PRINT(("success\n"));
                ConnectionSmSetSdpSecurityIn(TRUE);
				ConnectionSmSetSdpSecurityOut(TRUE, &SIMPLE.bd_addr);

				CodecInitCsrInternal(codec, &SIMPLE.task);
				AghfpInit ( &SIMPLE.task, aghfp_handsfree_15_profile, aghfp_incoming_call_reject | aghfp_inband_ring);                
            }
            else
            {
                PRINT(("failure : %d\n", msg->status));
                Panic();
            }
        
            break;
        }
    case CL_SM_PIN_CODE_IND:
        {
			CL_SM_PIN_CODE_IND_T *msg = (CL_SM_PIN_CODE_IND_T*)message;
		    uint16 pin_length = 0;
		    uint8 pin[16];
		    
		    PRINT(("CL_SM_PIN_CODE_IND\n"));
		    
	        /* Do we have a fixed pin in PS, if not reject pairing (by setting the length to zero) */ 
	        if ((pin_length = PsFullRetrieve(PSKEY_FIXED_PIN, pin, 16)) == 0 || pin_length > 16)
            {
                PRINT(("No pin, reject pairing\n"));
	            pin_length = 0; 
            }
		    
		    /* Respond to the PIN code request */
		    ConnectionSmPinCodeResponse(&msg->taddr, pin_length, pin); 
            break;
        }
    case CL_SM_IO_CAPABILITY_REQ_IND:
    {
        CL_SM_IO_CAPABILITY_REQ_IND_T* ind = (CL_SM_IO_CAPABILITY_REQ_IND_T*)message;
        PRINT(("CL_SM_IO_CAPABILITY_REQ_IND\n"));
        ConnectionSmIoCapabilityResponse(&ind->bd_addr, cl_sm_io_cap_no_input_no_output, FALSE, TRUE, FALSE, NULL, NULL);
        break;
    }
	case CL_SM_AUTHORISE_IND:
	{
		CL_SM_AUTHORISE_IND_T *msg = (CL_SM_AUTHORISE_IND_T*)message;

		PRINT(("CL_SM_AUTHORISE_IND\n"));
		
		PRINT(("    BD Addr : 0x%X 0x%X 0x%X%X\n", msg->bd_addr.nap, msg->bd_addr.uap, (uint16)(msg->bd_addr.lap>>16), (uint16)(msg->bd_addr.lap&0xFFFF)));
			ConnectionSmAuthoriseResponse(&msg->bd_addr, msg->protocol_id, msg->channel, msg->incoming, TRUE);
		
		break;
	}

        
	case AGHFP_INIT_CFM:
		{
            AGHFP_INIT_CFM_T *msg = (AGHFP_INIT_CFM_T*)message;
            AudioPluginFeatures features;

            /* determine additional features applicable for this audio plugin */
            features.stereo = FALSE;
            features.use_i2s_output = FALSE;
        			
            PRINT(("AGHFP_INIT_CFM\n"));
            if (msg->status == success)
            {
				SIMPLE.aghfp = msg->aghfp ;
					/*now allow buttons */
				pioInit(&SIMPLE.pio_state, &SIMPLE.task ) ;
	
				ledsPlay ( RED_BLUE_ALT_RPT_FAST) ;	
				AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
				ConnectionWriteScanEnable(hci_scan_enable_inq_and_page);
            }
            else
            {
                PRINT(("failure : %d\n", msg->status));
                Panic();
            }
			break;
		}
		
	case AGHFP_SLC_CONNECT_CFM:
		{
            AudioPluginFeatures features;
			AGHFP_SLC_CONNECT_CFM_T *msg = (AGHFP_SLC_CONNECT_CFM_T*)message;
            
            /* determine additional features applicable for this audio plugin */
            features.stereo = FALSE;
            features.use_i2s_output = FALSE;


            PRINT(("AGHFP_SLC_CONNECT_CFM\n"));
            if (msg->status == aghfp_success)
            { 
				PRINT(("success\n"));
				SIMPLE.connected =TRUE ;
				
				SIMPLE.rfcomm_sink = msg->rfcomm_sink;
				
				AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
				
				ledsPlay( BLUE_ONE_SEC_ON_RPT ) ;	
	        }
            else
            { 
                PRINT(("failure : %d\n", msg->status));
				
				AudioPlayTone( bad_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
			}
			
			
			break;
			
		}
	case AGHFP_AUDIO_CONNECT_CFM:
		{
			AGHFP_AUDIO_CONNECT_CFM_T *msg = (AGHFP_AUDIO_CONNECT_CFM_T*)message;
			PRINT(("AGHFP_AUDIO_CONNECT_CFM\n"));
            if (msg->status == aghfp_success)                
            { /* SCO Created, Plumb in the DSP */
                AudioPluginFeatures features = {0,0,0}; /* no stereo or i2s output */

                TaskData * lPlugin = NULL ;
                
                PRINT(("success [%x]\n" , (int)msg->audio_sink));
 
				SIMPLE.audio = TRUE ;
				SIMPLE.audio_sink = msg->audio_sink ;
				
				/* Extract the codec negotiated if we are setting up WBS. */
				if (msg->using_wbs)
				{
					audio_codec_type codec_type = audio_codec_wbs_sbc;
				
					/* Translate from WBS module codec type to Headset codec type */
					if(!wbsEnumToGlobalCodecEnum(msg->wbs_codec, &codec_type))
					{
						PRINT(("\tUnknown WBS codec.\n"));
						Panic();
					}
				
					SIMPLE.audio_codec = codec_type;	  

					/* Let the app know that a codec has been negotiated. */
					SIMPLE.codec_negotiated = TRUE;
				}	
				
#ifdef DEBUG_REVERT_TO_CVSD_ON_HF_INITIATED_AUDIO
				if(revertToCvsdFlag) SIMPLE.audio_codec = audio_codec_cvsd;
#endif /* DEBUG_REVERT_TO_CVSD_ON_HF_INITIATED_AUDIO */
				
				/* Set up the appropriate plug in */
				switch (SIMPLE.audio_codec)
				{
						case(audio_codec_cvsd):
							/* Not implemented yet. Revert to CVSD with no DSP */
							lPlugin = (TaskData *)&csr_cvsd_no_dsp_plugin;
							break;
						case(audio_codec_wbs_sbc):
							lPlugin = (TaskData *)&csr_sbc_1mic_plugin;
							break;
						case(audio_codec_wbs_amr):
							/* Not implemented yet. */
							PRINT(("\tAMR not yet implemented.\n"));
							Panic();
							break;
						case(audio_codec_wbs_evrc):
							/* Not implemented yet. */
							PRINT(("\tEVRC not yet implemented.\n"));
							Panic();
							break;
						default:
							break;
				}
				             
				AudioConnect (  lPlugin ,
								 SIMPLE.audio_sink ,
								 msg->link_type ,
								 SIMPLE.codec_task,
								 SIMPLE.volume,
								 msg->tx_bandwidth,
								 features ,                        /* no stereo or I2S output required */
								 AUDIO_MODE_CONNECTED ,
                                 AUDIO_ROUTE_INTERNAL,
                                 POWER_BATT_LEVEL3,
                                 NULL,
								 0 );
 									
				switch (msg->link_type)
		        {
        		    case (sync_link_unknown):
        	    	    PRINT(("AUD: Link = ?\n")) ;
		            break ;
	    	        case (sync_link_sco) :
        	    	    PRINT(("AUD: Link = SCO\n")) ;
            		break;
	    	        case sync_link_esco:	
    		            PRINT(("AUD: Link = eSCO\n")) ;
	        	    break ;    
        		}
				ledsPlay( BLUE_SHORT_ON_RPT ) ;
				
				
				/* Set up our sniff sub rate params for SCO */
               ConnectionSetSniffSubRatePolicy(	SIMPLE.rfcomm_sink, 
												SIMPLE.ssr_data.sco_params.max_remote_latency, 
												SIMPLE.ssr_data.sco_params.min_remote_timeout, 
												SIMPLE.ssr_data.sco_params.min_local_timeout);

			}     
			else
            {
                PRINT(("failed [%x]\n" , msg->status));
            }
		}
		
	break ;
	case AGHFP_SLC_DISCONNECT_IND:
		{
            AudioPluginFeatures features;

            /* determine additional features applicable for this audio plugin */
            features.stereo = FALSE;
            features.use_i2s_output = FALSE;
            
#ifdef DEBUG_PRINT_ENABLED
			AGHFP_SLC_DISCONNECT_IND_T *msg = (AGHFP_SLC_DISCONNECT_IND_T*)message;
			PRINT(("AGHFP_SLC_DISCONNECT_IND%d\n", msg->status));		
#endif            
			SIMPLE.connected = FALSE ;
			
			ledsPlay ( RED_BLUE_ALT_RPT_FAST) ;	
			
			AudioPlayTone( bad_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
		}
	break;
	case AGHFP_AUDIO_DISCONNECT_IND:
			PRINT(("AGHFP_AUDIO_DISCONNECT_IND\n"));
			SIMPLE.audio = FALSE ;
			
			AudioDisconnect() ;
            
            /* Set up our sniff sub rate params for SLC */
			ConnectionSetSniffSubRatePolicy(SIMPLE.rfcomm_sink, 
                                            SIMPLE.ssr_data.slc_params.max_remote_latency, 
                                            SIMPLE.ssr_data.slc_params.min_remote_timeout, 
                                            SIMPLE.ssr_data.slc_params.min_local_timeout);

		    ledsPlay( BLUE_ONE_SEC_ON_RPT ) ;	
	break;
		
	case AGHFP_SLC_CONNECT_IND:
	{
		PRINT(("AGHFP_SLC_CONNECT_IND\n"));
		AghfpSlcConnectResponse(SIMPLE.aghfp, TRUE);
		
		ledsPlay( BLUE_ONE_SEC_ON_RPT ) ;	
	}
	break;
	case AGHFP_AUDIO_CONNECT_IND:
	{
		AGHFP_AUDIO_CONNECT_IND_T *msg = (AGHFP_AUDIO_CONNECT_IND_T*)message;
        AudioPluginFeatures features;

        /* determine additional features applicable for this audio plugin */
        features.stereo = FALSE;
        features.use_i2s_output = FALSE;

        PRINT(("AGHFP_AUDIO_CONNECT_IND\n"));
		
		
		if (SIMPLE.audio_codec == audio_codec_cvsd)
		{
			PRINT(("AUDIOPARAMS >ESCO: [%x] [%x]\n", SIMPLE.audio_cvsd_params.syncPktTypes , SIMPLE.audio_cvsd_params.hfpAudioParams.max_latency )) ;
			AghfpAudioConnectResponse(msg->aghfp, TRUE , SIMPLE.audio_cvsd_params.syncPktTypes, &SIMPLE.audio_cvsd_params.hfpAudioParams );                
		}
		else
		{
			PRINT(("AUDIOPARAMS >ESCO: [%x] [%x]\n", SIMPLE.audio_auristream_params.syncPktTypes , SIMPLE.audio_auristream_params.hfpAudioParams.max_latency )) ;
			AghfpAudioConnectResponse(msg->aghfp, TRUE , SIMPLE.audio_auristream_params.syncPktTypes, &SIMPLE.audio_auristream_params.hfpAudioParams );                
		}
		
		AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
	}
	break ;	
		
	
	case AGHFP_CSR_SUPPORTED_FEATURES_IND:
	{
        AGHFP_CSR_SUPPORTED_FEATURES_IND_T *msg = (AGHFP_CSR_SUPPORTED_FEATURES_IND_T*)message ;

		if(SIMPLE.csr_codec_negotiation_capable)
		{
			auristream_codec_masks	codec;

			/* Save the HF's CSR supported features. */
			SIMPLE.hf_csr_codecs = msg->codecs;

			/* Reset flags. */
			SIMPLE.ag_initiated_at_csrfn_resolved 		= FALSE;
			SIMPLE.ag_initiated_csr_codec_negotiation 	= FALSE;

			if(msg->codec_bandwidths_present)
			{
				SIMPLE.hf_csr_codec_bandwidths = msg->codec_bandwidths;
				SIMPLE.hf_supports_csr_bw_negotiation = 1;
				SIMPLE.hf_supports_csr_hf_initiated_codec_negotiation = 1;
			}
						

			aghfpCsrSupportedFeaturesResponse (msg->aghfp, 0 , 0,0,0,0,AG_CSR_SUPPORTED_FEATURES, msg->codec_bandwidths_present, AG_CSR_SUPPORTED_FEATURES_BW) ;

			/* Negotiate Auristream if a CSR codec is specified. */
			if(globalCodecEnumToCsrBitmap(SIMPLE.codec_to_negotiate, &codec) &&
				   (SIMPLE.negotiation_type == aghfp_codec_negotiation_type_csr))
			{
				/* Save the fact that this is an AG initiated CSR CODEC negotiation. */
				SIMPLE.ag_initiated_csr_codec_negotiation = TRUE;
				/* Note that if the HF supports CSR CODEC bandwidth negotiation we can add it. */
				aghfpFeatureNegotiate(msg->aghfp, (SIMPLE.hf_supports_csr_bw_negotiation?2:1), 6, codec, 7, SIMPLE.csr_codec_bandwidth_to_negotiate, FALSE);
			}
				
				/* This signifies that the SLC establishment is complete. This is here to let
				   messages sent conditionally on this variable that they should sent
				   their message now. This situation occurs when the user clicks on a action
				   which requires an SLC, but one had not yet been established. */
			SIMPLE.connecting_slc = FALSE;
		}
		else
		{
				AghfpSendError(msg->aghfp);
        }
       	
	}
	break ;
	
	case AGHFP_CSR_FEATURE_NEGOTIATION_IND:
	{
        	AGHFP_CSR_FEATURE_NEGOTIATION_IND_T *msg = (AGHFP_CSR_FEATURE_NEGOTIATION_IND_T*)message ;
		    uint16				codec = 0;
		    uint16				bandwidth = NO_BANDWIDTH_SPECIFIED;
		    uint16				counter1;
		    
			PRINT(("CSR2CSR FEAT NEG IND " ));

			/* Parse the CSRFN indicator values. */
			for(counter1 = 0; counter1 < msg->num_csr_features; counter1++)
			{
				PRINT(("%s[%d],[%d]", counter1 == 0 ? "" : ",", msg->csr_features[counter1].indicator , msg->csr_features[counter1].value));
			
				switch(msg->csr_features[counter1].indicator)
				{
					case(csr2csr_codecs):
						codec = msg->csr_features[counter1].value;
						break;
					case(csr2csr_codec_bandwidth):
						bandwidth = msg->csr_features[counter1].value;
						break;
				}
			}

			PRINT(("\n"));

			if(SIMPLE.hf_supports_csr_hf_initiated_codec_negotiation &&
			   !SIMPLE.ag_initiated_csr_codec_negotiation)
			{
				audio_codec_type	audio_codec_selected;
				
				if(csr2csrHandleFeatureNegotiationHfInitiated(msg->aghfp, msg->num_csr_features, codec, bandwidth, &audio_codec_selected))
				{
					/*store the codec*/
					SIMPLE.audio_codec = SIMPLE.codec_to_negotiate;

					/* Let AGHFP know that the app has negotiated its codec. */
					AghfpClearAppCodecNegotiationPending(msg->aghfp);

					/* Let the app know that a codec has been negotiated (for querying via API). */
					SIMPLE.codec_negotiated = TRUE;

					/* Start the audio. */
 					AghfpStartAudioAfterAppCodecNegotiation(msg->aghfp, SIMPLE.audio_params.syncPktTypes, &SIMPLE.audio_params.hfpAudioParams);
				}
			}
			else
			{
				if(csr2csrHandleFeatureNegotiationAgInitiated(msg->aghfp, msg->num_csr_features, codec, bandwidth, SIMPLE.codec_to_negotiate))
				{
					/* AG initiated CSR CODEC negotiation has now successfully completed. */
					/* Note and continue with SCO/eSCO. */
					SIMPLE.ag_initiated_at_csrfn_resolved = TRUE;
					SIMPLE.ag_initiated_csr_codec_negotiation = FALSE;

					/*store the codec*/
					SIMPLE.audio_codec = SIMPLE.codec_to_negotiate;

					/* Let AGHFP know that the app has negotiated its codec. */
					AghfpClearAppCodecNegotiationPending(msg->aghfp);

					/* Let the app know that a codec has been negotiated. */
					SIMPLE.codec_negotiated = TRUE;

					if(SIMPLE.start_audio_after_codec_negotiation)
					{
						SIMPLE.start_audio_after_codec_negotiation = FALSE;

	 					AghfpStartAudioAfterAppCodecNegotiation(msg->aghfp, SIMPLE.audio_params.syncPktTypes, &SIMPLE.audio_params.hfpAudioParams);
					}
				}
			}        	
	}
	break ;
	
	case CODEC_INIT_CFM:
		{
            AudioPluginFeatures features;
			CODEC_INIT_CFM_T *msg = (CODEC_INIT_CFM_T*)message;
            
            Source source_a = StreamSourceFromSink(StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_A));
			Source source_b = StreamSourceFromSink(StreamAudioSink(AUDIO_HARDWARE_CODEC, AUDIO_INSTANCE_0, AUDIO_CHANNEL_B));
            
            /* determine additional features applicable for this audio plugin */
            features.stereo = FALSE;
            features.use_i2s_output = FALSE;            
            

			SIMPLE.codec_task = msg->codecTask;
			PRINT(("CODEC_INIT_CFM\n"));
            SourceConfigure(source_a, STREAM_CODEC_MIC_INPUT_GAIN_ENABLE, FALSE);
            SourceConfigure(source_b, STREAM_CODEC_MIC_INPUT_GAIN_ENABLE, FALSE);

            
#ifdef CHIPBASE_BC5
        /* set current and voltage to magic values*/
        MicbiasConfigure(MIC_BIAS_0, MIC_BIAS_ENABLE, MIC_BIAS_AUTOMATIC_ON);
        MicbiasConfigure(MIC_BIAS_0, MIC_BIAS_CURRENT, 11);
        MicbiasConfigure(MIC_BIAS_0, MIC_BIAS_VOLTAGE, 7);
    
#endif
            SourceConfigure(source_a, STREAM_CODEC_RAW_INPUT_GAIN, 7);
            SourceConfigure(source_b, STREAM_CODEC_RAW_INPUT_GAIN, 7);
	
			AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
			
			read_config() ;
		 	
		}
	break ;
		
	case BUTTON_MFB_PRESS:
		PRINT(("BUTTON_MFB_PRESS\n"));
		{
				/*only disconnect if connected without audio*/
			if ((SIMPLE.connected) && ( ! SIMPLE.audio) )
			{
				AghfpSlcDisconnect ( SIMPLE.aghfp) ;		
			}
			else
			{
				AghfpSlcConnect(SIMPLE.aghfp, &SIMPLE.bd_addr);
			}	
		}
	break ;
	case BUTTON_FCN_PRESS:
		{
			PRINT(("BUTTON_FCN_PRESS[%x]\n" , SIMPLE.connected));		
			
            if (SIMPLE.connected)
            {
    			PRINT(("toggle AUDIO [%x]\n" ,  SIMPLE.audio));	  
		      	if (SIMPLE.audio)
        		{
			     	PRINT(("AUDIO DISCONNECT\n")) ;
	       			AghfpAudioDisconnect(SIMPLE.aghfp );                
    			}
			    else
			    {
	       			PRINT(("AUDIO CONNECT\n")) ;
				
    				if (SIMPLE.audio_codec == audio_codec_cvsd)
			     	{
		  			PRINT(("AUDIOPARAMS CVSD >ESCO: [%x] [%x]\n", SIMPLE.audio_cvsd_params.syncPktTypes , SIMPLE.audio_cvsd_params.hfpAudioParams.max_latency )) ;
	   				AghfpAudioConnect(SIMPLE.aghfp,  SIMPLE.audio_cvsd_params.syncPktTypes, &SIMPLE.audio_cvsd_params.hfpAudioParams );                
    			 	}
			     	else
	       			{
    					PRINT(("AUDIOPARAMS AURISTREAM >ESCO: [%x] [%x]\n", SIMPLE.audio_auristream_params.syncPktTypes , SIMPLE.audio_auristream_params.hfpAudioParams.max_latency )) ;
					   AghfpAudioConnect(SIMPLE.aghfp, SIMPLE.audio_auristream_params.syncPktTypes, &SIMPLE.audio_auristream_params.hfpAudioParams );                
				    }
                }
            }
        }
	break ;
	case BUTTON_VOL_UP:
	{
        AudioPluginFeatures features;

        /* determine additional features applicable for this audio plugin */
        features.stereo = FALSE;
        features.use_i2s_output = FALSE;
        
    	PRINT(("BUTTON_VOL_UP\n"));
		
		if (SIMPLE.volume < 0x16)
	    {
			SIMPLE.volume++;
		
			AudioSetVolume(	SIMPLE.volume ,SIMPLE.volume , SIMPLE.codec_task ) ;
			
			AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
		}
		else
		{		
			AudioPlayTone( bad_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
		}
	}
	break;
            
    case BUTTON_VOL_DOWN:
	{
        AudioPluginFeatures features;

        /* determine additional features applicable for this audio plugin */
        features.stereo = FALSE;
        features.use_i2s_output = FALSE;

		PRINT(("BUTTON_VOL_DOWN\n"));
		if (SIMPLE.volume > 0)
		{
	 		SIMPLE.volume--;		
		
			AudioSetVolume(	SIMPLE.volume , SIMPLE.volume , SIMPLE.codec_task ) ;
		
			AudioPlayTone( good_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;		 
		}
		else
		{
			AudioPlayTone( bad_tone , TRUE , SIMPLE.codec_task, 0x15, features) ;
		}
	}
    break;

    default:
        PRINT(("Main Unhandled Message : %d , 0x%0X\n",id,id)); 
        break;
    }
}
int main(void)
{

	PioSetDir32((1<<4),(1<<4)); 
	PioSet32((1<<4), (1<<4) );
	
	PRINT(("Simple AG Demo App. Started\n"));

    /*latch on the power*/
    PsuConfigure(PSU_SMPS0, PSU_ENABLE, TRUE);
	ChargerConfigure(CHARGER_SUPPRESS_LED0, TRUE);	
    /* Set up task handler */
    SIMPLE.task.handler = profile_handler;	
	
	SIMPLE.audio = FALSE ;
	
	SIMPLE.audio_codec = audio_codec_cvsd ;
	SIMPLE.codec_to_negotiate = audio_codec_cvsd ;
    
    /* Set codec negotiation variables to sensible values. */
	SIMPLE.codec_to_negotiate = audio_codec_cvsd;
	SIMPLE.csr_codec_bandwidth_to_negotiate = auristream_bw_mask_8k;
	SIMPLE.negotiation_type = aghfp_codec_negotiation_type_none;
	SIMPLE.codec_negotiated = FALSE;
	SIMPLE.csr_codec_negotiation_capable = FALSE;
	SIMPLE.start_audio_after_codec_negotiation = FALSE;
	SIMPLE.hf_csr_codecs = 0;
	SIMPLE.hf_csr_codec_bandwidths = 0;
	SIMPLE.hf_supports_csr_bw_negotiation = 0;
	SIMPLE.hf_supports_csr_hf_initiated_codec_negotiation = 0;
	
	
	SIMPLE.volume = 0x0a ;
	
    /* Start the connection library */
    ConnectionInit(&SIMPLE.task);

    /* Start the message scheduler loop */
    MessageLoop();

    /* Never get here! */
    return 0;
}

