/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2009-2014
Part of ADK 3.5

DESCRIPTION
	Interface definition for handling MAP Client library messages and functionality

	
FILE
	sink_mapc.h
*/

#ifndef SINK_MAPC_H
#define SINK_MAPC_H

#ifdef ENABLE_MAPC

#include <message.h>
#include <bdaddr.h>
#include <mapc.h>

#define MAX_MAPC_CONNECTIONS    2 

/* Mapc link priority is used to identify different mapc links to
   AG devices using the order in which the devices were connected. 
*/
typedef enum
{
    /*! First mapc link */
    mapc_primary_link,
    /*! Second mapc link */
    mapc_secondary_link, 
    /*! Invalid mapc link */
    mapc_invalid_link
} mapc_link_priority;

/* Mapc Session Connection state */
typedef enum
{
    /* mapc session idle */
    mapc_state_idle,
    /* mapc mas session connecting */
    mapc_mas_connecting,
    /* mapc sdp search completed */
    mapc_sdp_searched,
    /* mapc mas session connected */
    mapc_mas_connected,
    /* mapc mns session registering */
    mapc_mns_registering,
    /* mapc mns session registered */
    mapc_mns_registered,
    /* mapc mas session disconnecting */
    mapc_mas_disconnecting,
    /* mapc mns session unregistering */
    mapc_mns_unregistering
    
} mapc_state;

typedef enum
{
    /*! mapc no action. */
    mapc_unstarted,
    /*! mapc message notification. */
    mapc_starting,
    /*! mapc closing map access/notification service. */
    mapc_started,
    /*! mapc message notification. */    
    mapc_closing
} mapc_mns_state;

/*!
    @brief Global data for mapc features.
*/
struct __mapcState
{
    /* Server Bluetooth address */
    bdaddr          bdAddr;
    /* The Mapc Mas Session */
    Mas             masHandle;
    /* The Mapc Mns Session */
    Mns             mnsHandle;
    /* The Mns rfcomm Channel for the MNS Service */
    uint8           mnsChannel;
    /* The Mas rfcomm Channel for the MAS Service */
    uint8           masChannel;
    /* Device id for mapc connection */
    mapc_state      device_state;
};

typedef struct __mapcState mapcState;

struct __mapcData
{
    mapcState       state[MAX_MAPC_CONNECTIONS];
    
    /* The SDP record handle of the MNS Service */
    uint32          sdpHandle;
    
    /* The Mns rfcomm Channel for the MNS Service */
    unsigned        mnsChannel:8;
             
    mapc_state      mapcState;
};

typedef struct __mapcData mapcData_t;

#define MAPC_APP_MESSAGE_BASE (MAPC_API_MESSAGE_END + 1)

typedef enum
{
    /* Initialization */
    MAPC_APP_MNS_START = MAPC_APP_MESSAGE_BASE,
    MAPC_APP_MAS_CONNECT,
    MAPC_APP_MAS_DISCONNECT,
    MAPC_APP_MAS_SET_NOTIFICATION,
    
    MAPC_APP_MESSAGE_TOP 

} MapcAppMessageId;


typedef struct{
    bdaddr   bdAddr;
    uint16   device_id;
}MAPC_APP_MAS_CONNECT_T;

typedef struct{
    Mas         masSession;    /*!< The session handle. Invalid on failure */ 
    bool        action;
}MAPC_APP_MAS_SET_NOTIFICATION_T;

typedef struct{
    Mas         masSession;    /*!< The session handle. Invalid on failure */ 
}MAPC_APP_MAS_DISCONNECT_T;

typedef struct 
{
    bdaddr bdAddr;
    
} MAPC_ADDR_t;
/****************************************************************************
NAME	
	initMap
    
DESCRIPTION
    Register the Map Notification Service
    
PARAMS
    none
    
RETURNS
	void
*/
void initMap(void);

/****************************************************************************
NAME	
	mapcShutDown
    
DESCRIPTION
    Unregister the Map Notification Service, called at shut down
    
PARAMS
    none
    
RETURNS
	void
*/
void mapcShutDown(void);

/****************************************************************************
NAME	
	mapcEnableMns
DESCRIPTION
    Enable Map Message Notification Service
    
PARAMS
    void
    
RETURNS
	void
*/
void mapcEnableMns(void);

/****************************************************************************
NAME	
	mapcDisconnectMns
DESCRIPTION
    Disaable Map Message Notification Service
    
PARAMS
    void
    
RETURNS
	void
*/
void mapcDisconnectMns(void);

/****************************************************************************
NAME	
	handleMapcMessages
DESCRIPTION
    MAP Client Message Handler
    
PARAMS
    task        associated task
    pId         message id           
    pMessage    message
    
RETURNS
	void
*/
void handleMapcMessages(Task task, MessageId pId, Message pMessage);

/****************************************************************************
NAME	
	mapcHandleServiceSearchAttributeCfm
    
DESCRIPTION
    handle CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T message for mapc sdp service search 
    
PARAMS
    task        associated task
    pId         message id           
    pMessage    message
    
RETURNS
	void
*/
void mapcHandleServiceSearchAttributeCfm( const CL_SDP_SERVICE_SEARCH_ATTRIBUTE_CFM_T *cfm);

/****************************************************************************
NAME	
	mapcMasConnectRequest
    
DESCRIPTION
    Start Mas connection, including add device and then sdp search, for the
    HFP and A2DP connected devices
    
PARAMS
    @bdaddr
    
RETURNS
	void
*/
void mapcMasConnectRequest(bdaddr * pAddr);

#endif /*ENABLE_MAPC*/
								
#endif /* SINK_MAPC_H */

