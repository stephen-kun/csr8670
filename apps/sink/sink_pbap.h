/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2009-2014
Part of ADK 3.5

DESCRIPTION
	Interface definition for handling PBAP library messages and functionality

	
FILE
	sink_pbap.h
*/


#ifndef SINK_PBAP_H
#define SINK_PBAP_H

#ifdef ENABLE_PBAP

#include <message.h>
#include <pbapc.h>

/* PBAP Client Data */
#define PBAPC_FILTER_VERSION        (1<<0)
#define PBAPC_FILTER_FN             (1<<1)
#define PBAPC_FILTER_N              (1<<2)
#define PBAPC_FILTER_TEL            (1<<7)
#define PBAPC_FILTER_LOW            ((uint32)(PBAPC_FILTER_N | PBAPC_FILTER_TEL))
#define PBAPC_FILTER_HIGH           ((uint32)0)
#define PBAPC_MAX_LIST              (1000)
#define PBAPC_LIST_START            (0)

/*!
    @brief Pbap link priority is used to identify different pbapc links to
    AG devices using the order in which the devices were connected.
*/
typedef enum
{
    /*! pbapc no action. */
    pbapc_action_idle,
    /*! pbapc setting phonebook. */
    pbapc_setting_phonebook,
    /*! pbapc dialling */
    pbapc_dialling,    
    /*! pbapc browsing phonebook entry. */
    pbapc_browsing_entry,
    /*! pbapc browsing phonebook list. */
    pbapc_browsing_list,
    /*! pbapc downloading phonebook. */
    pbapc_downloading,
    /*! pbapc getting phonebook size. */
    pbapc_phonebooksize    
} pbapc_command;

/*!
    @brief Global data for pbapc features.
*/
typedef struct 
{	
    uint16         PbapBrowseEntryIndex;
    
    unsigned       pbap_active_pb:3;
    unsigned       pbap_ready:1;               /* pbapc library has been initialised */
    unsigned       pbap_command:3;
    unsigned       pbap_browsing_start_flag:1;
    unsigned       pbap_active_link:2;
    unsigned       pbap_phone_repository:2;
    unsigned       pbap_hfp_link:4;
} pbapc_data_t;

/*!
    @brief define internal pbapc messages.
*/
#define PBAPC_APP_MSG_BASE   (PBAPC_MESSAGE_TOP + 1)
typedef enum
{
    /* Session Control */
    PBAPC_APP_PULL_VCARD_ENTRY = PBAPC_APP_MSG_BASE,
    PBAPC_APP_PULL_VCARD_LIST,
    PBAPC_APP_PULL_PHONE_BOOK,
    PBAPC_APP_PHONE_BOOK_SIZE,
    
    PBAPC_APP_MSG_TOP
} PbapcAppMsgId;

/****************************************************************************
NAME	
	handlePbapMessages
DESCRIPTION
    PBAP Server Message Handler
    
PARAMS
    task        associated task
    pId         message id           
    pMessage    message
    
RETURNS
	void
*/
void handlePbapMessages(Task task, MessageId pId, Message pMessage);


/****************************************************************************
NAME	
	initPbap

DESCRIPTION
    Initialise the PBAP System
    
PARAMS
    void
    
RETURNS
	void
*/
void initPbap(void);


/****************************************************************************
NAME	
	pbapConnect

DESCRIPTION
    Connect to PBAP Server
    
PARAMS
    pbap_hfp_link   hfp device with priority hfp_link to connect pbap
    
RETURNS
    bool
*/
bool pbapConnect( hfp_link_priority pbap_hfp_link );


/****************************************************************************
NAME	
	pbapDisconnect

DESCRIPTION
    Disconnect from PBAP Server
    
PARAMS
    void
    
RETURNS
	void
*/
void pbapDisconnect(void);


/****************************************************************************
NAME	
	pbapDialPhoneBook

DESCRIPTION
    Dial the first entry in the phonebook
    
PARAMS
    void
    
RETURNS
	void
*/
void pbapDialPhoneBook( uint8 phonebook );


#endif /*ENABLE_PBAP*/
								
#endif /* SINK_PBAP_H */
