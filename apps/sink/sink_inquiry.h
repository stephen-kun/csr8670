/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004-2014

FILE NAME
    sink_inquiry.h
    
DESCRIPTION
    
*/

#ifndef _SINK_INQUIRY_H_
#define _SINK_INQUIRY_H_

typedef enum
{
    remote_device_unknown,
    remote_device_nonpeer,
    remote_device_peer
} remote_device;


typedef enum
{
    remote_features_shareme_a2dp_sink     = 0x01,
    remote_features_shareme_a2dp_source   = 0x02,
    remote_features_tws_a2dp_sink         = 0x04,
    remote_features_tws_a2dp_source       = 0x08,
    remote_features_peer_avrcp_target     = 0x10,
    remote_features_peer_avrcp_controller = 0x20,
    remote_features_peer_sink             = (remote_features_shareme_a2dp_sink | remote_features_tws_a2dp_sink),
    remote_features_peer_source           = (remote_features_shareme_a2dp_source | remote_features_tws_a2dp_source),
    remote_features_peer_avrcp            = (remote_features_peer_avrcp_target | remote_features_peer_avrcp_controller)
} remote_features;


/* Inquiry action */
typedef enum
{
    profile_none  = 0x00,
    profile_hsp   = 0x01,
    profile_hfp   = 0x02,
    profile_a2dp  = 0x04,
    profile_avrcp = 0x08
} supported_profiles;

#define SUPPORTED_PROFILE_COUNT 4


/* Inquiry session */
typedef enum
{
    inquiry_session_normal,   /* Normal inquiry session, for finding AGs etc */
    inquiry_session_peer      /* Peer inquiry session, for finding peer devices */
} inquiry_session;

/* Inquiry action */
typedef enum
{
    rssi_none,
    rssi_pairing,
    rssi_connecting,
    rssi_subwoofer
} inquiry_action;

/* Inquiry state */
typedef enum
{
    inquiry_idle,
    inquiry_searching,
    inquiry_connecting,
    inquiry_complete
} inquiry_state;

/* Inquiry result */
typedef struct
{
    bdaddr bd_addr;                     /* Address of device */
    int16  rssi;                        /* Highest received signal strength indication from device */
#ifdef ENABLE_PEER
    unsigned           :4;                  /* Unused */ 
    remote_device      peer_device:2;       /* Indicates that the remote device is of the same type as the local one */
    remote_features    peer_features:6;     /* Bitmask of Peer device features supported on remote device */
    supported_profiles remote_profiles:4;   /* Bitmask of profiles supported by a remote device */
#endif
}inquiry_result_t;

/* Inquiry run time data */
typedef struct
{
    inquiry_session    session:1;             /* Inquiry session (normal/peer)       */
    inquiry_action     action:2;              /* Inquiry Action (pairing/connecting)  */
    inquiry_state      state:2;               /* Inquiry State (searching/connecting) */
    unsigned           attempting:4;          /* Index of device being connected to   */
    supported_profiles remote_profiles:4;     /* Bitmask of profiles supported by a remote device */
    unsigned           profile_search_idx:3;  /* Index of current sdp service search */
    inquiry_result_t*  results;               /* Array of inquiry results             */
}inquiry_data_t;

/* Inquiry Config */
typedef struct
{
    uint16      tx_power;               /* The inquiry Tx power */
	uint16      threshold;              /* The minimum RSSI reading for an AG to be paired */
	uint16      diff_threshold;         /* The required difference between AG and next closest AG */
    uint32      cod_filter;             /* COD to consider */
	uint16      conn_threshold;         /* The minimum RSSI reading for an AG to be connected */
	uint16      conn_diff_threshold;    /* The required difference between AG and next closest AG */
    unsigned    max_responses:8;        /* Maximum number of inquiry responses (0 = unlimited) */
    unsigned    timeout:8;              /* Maximum inquiry time (timeout * 1.28s) */
    unsigned    resume_timeout:8;       /* Time to wait between inquiry attempts */
    unsigned    num_results:4;          /* Number of results we can store */
    unsigned    connect_if_in_pdl:1;    /* Don't connect to an AG if not already in the PDL */
    unsigned    dont_pair_if_in_pdl:1;  /* Don't pair with an AG if already in the PDL */
    unsigned    try_all_discovered:1;   /* Attempt to pair/connect to all discovered AGs */
    unsigned    pair_on_pdl_reset:1;    /* Start RSSI pairing on PDL reset event */
}rssi_pairing_t ;


/* Inquiry reminder timeout */
#define INQUIRY_REMINDER_TIMEOUT_SECS 5
#define RSSI_CONF            (theSink.conf2->rssi)
#define INQUIRY_ON_PDL_RESET (RSSI_CONF.pair_on_pdl_reset)
    

void handleSdpOpenCfm (CL_SDP_OPEN_SEARCH_CFM_T *cfm);
void handleSdpCloseCfm (CL_SDP_CLOSE_SEARCH_CFM_T *cfm);
void HandleSdpServiceSearchAttributeCfm (CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *cfm);

/****************************************************************************
NAME    
    HandleSdpServiceSearchCfm
    
DESCRIPTION
    Handle SDP service search result notifications
RETURNS
    void
*/
void HandleSdpServiceSearchCfm (CL_SDP_SERVICE_SEARCH_CFM_T *cfm);


/****************************************************************************
NAME    
    inquiryReset
    
DESCRIPTION
    Reset inquiry data to initial values
RETURNS
    void
*/
void inquiryReset( void );


/****************************************************************************
NAME    
    inquiryResume
    
DESCRIPTION
    Reset inquiry results and resume
RETURNS
    void
*/
void inquiryResume(void);


/****************************************************************************
NAME    
    inquiryPair
    
DESCRIPTION
    Kick off inquiry and pairing
RETURNS
    bool
*/
bool inquiryPair( inquiry_session session, bool req_disc );


/****************************************************************************
NAME    
    inquiryStart
    
DESCRIPTION
    Kick off Inquiry
RETURNS
    void
*/
void inquiryStart( bool req_disc );


/****************************************************************************
NAME    
    inquiryStop
    
DESCRIPTION
    Stop inquiry in progress.
RETURNS
    void
*/
void inquiryStop( void );


/****************************************************************************
NAME    
    inquiryTimeout
    
DESCRIPTION
    Inquiry process has timed out, wait for connections in progress to 
    complete and stop inquiring
RETURNS
    void
*/
void inquiryTimeout(void);


/****************************************************************************
NAME    
    inquiryConnectNext
    
DESCRIPTION
    Helper function to connect to next inquiry result
RETURNS
    void
*/
void inquiryConnectNext(void);


/****************************************************************************
NAME    
    inquiryHandleResult
    
DESCRIPTION
    Inquiry result received
RETURNS
    void
*/
void inquiryHandleResult( CL_DM_INQUIRE_RESULT_T* result );


/****************************************************************************
NAME    
    inquiryGetConnectingDevice
    
DESCRIPTION
    Returns the details of the device being attempted to connect following the inquiry procedure.
RETURNS
    void
*/
inquiry_result_t* inquiryGetConnectingDevice (void);



#endif /* _SINK_INQUIRY_H_ */

