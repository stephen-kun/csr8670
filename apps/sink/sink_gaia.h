/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2010-2014
Part of ADK 3.5

FILE NAME
    sink_gaia.h        

DESCRIPTION
    Header file for interface with Generic Application Interface Architecture
    library

NOTES

*/
#ifndef _SINK_GAIA_H_
#define _SINK_GAIA_H_

#include <gaia.h>
#include "sink_private.h"

#ifdef DEBUG_GAIA
#define GAIA_DEBUG(x) DEBUG(x)
#else
#define GAIA_DEBUG(x) 
#endif

#define GAIA_API_MINOR_VERSION (2)

#define GAIA_CONFIGURATION_LENGTH_POWER (28)
#define GAIA_CONFIGURATION_LENGTH_HFP (24)
#define GAIA_CONFIGURATION_LENGTH_RSSI (14)

#define GAIA_TONE_BUFFER_SIZE (94)
#define GAIA_TONE_MAX_LENGTH ((GAIA_TONE_BUFFER_SIZE - 4) / 2)

#define GAIA_ILLEGAL_PARTITION (15)
#define GAIA_DFU_REQUEST_TIMEOUT (30)

typedef struct
{
    unsigned word:8;
    unsigned posn:4;
    unsigned size:4;
} gaia_feature_map_t;


typedef struct
{
    unsigned fixed:1;
    unsigned size:15;
} gaia_config_entry_size_t;

/*For complete information about the GAIA commands, refer to the document GAIAHeadsetCommandReference*/

#define NUM_WORDS_GAIA_CMD_HDR 2 /*No. of words in GAIA Command header */

#define NUM_WORDS_GAIA_CMD_PER_EQ_PARAM 4 /*No. of words for each user EQ parameter in GAIA command*/

#define CHANGE_NUMBER_OF_ACTIVE_BANKS   0xFFFF
#define CHANGE_NUMBER_OF_BANDS          0xF0FF
#define CHANGE_BANK_MASTER_GAIN         0xF0FE
#define CHANGE_BAND_PARAMETER           0xF000
#define USER_EQ_BANK_INDEX              1

typedef enum
{
    PARAM_HI_OFFSET,
    PARAM_LO_OFFSET,
    VALUE_HI_OFFSET,
    VALUE_LO_OFFSET    
}gaia_cmd_payload_offset;


/*************************************************************************
NAME
    gaiaReportPioChange
    
DESCRIPTION
    Relay any registered PIO Change events to the Gaia client
    We handle the PIO-like GAIA_EVENT_CHARGER_CONNECTION here too
*/
void gaiaReportPioChange(uint32 pio_state);


/*************************************************************************
NAME
    gaiaReportEvent
    
DESCRIPTION
    Relay any significant application events to the Gaia client
*/
void gaiaReportEvent(uint16 id);


/*************************************************************************
NAME
    gaiaReportUserEvent
    
DESCRIPTION
    Relay any user-generated events to the Gaia client
*/
void gaiaReportUserEvent(uint16 id);

        
/*************************************************************************
NAME
    gaiaReportSpeechRecResult
    
DESCRIPTION
    Relay a speech recognition result to the Gaia client
*/
void gaiaReportSpeechRecResult(uint16 id);


/*************************************************************************
NAME
    handleGaiaMessage
    
DESCRIPTION
    Handle messages passed up from the Gaia library
*/
void handleGaiaMessage(Task task, MessageId id, Message message);


/*************************************************************************
NAME
    gaiaDfuRequest
    
DESCRIPTION
    Request Device Firmware Upgrade from the GAIA host
*/
void gaiaDfuRequest(void);


/*************************************************************************
NAME
    handleDfuSqifStatus
    
DESCRIPTION
    Handle MESSAGE_DFU_SQIF_STATUS from the loader
*/
void handleDfuSqifStatus(MessageDFUFromSQifStatus *message);


/*************************************************************************
NAME
    gaiaDisconnect
    
DESCRIPTION
    Disconnect from GAIA client
*/
void gaiaDisconnect(void);


/*************************************************************************
NAME    
    gaia_send_response
    
DESCRIPTION
    Build and Send a Gaia acknowledgement packet
   
*/ 
void gaia_send_response(uint16 vendor_id, uint16 command_id, uint16 status,
                          uint16 payload_length, uint8 *payload);


/*************************************************************************
NAME    
    gaia_send_response_16
    
DESCRIPTION
    Build and Send a Gaia acknowledgement packet from a uint16[] payload
   
*/ 
void gaia_send_response_16(uint16 command_id, uint16 status,
                          uint16 payload_length, uint16 *payload);


#endif /*_SINK_GAIA_H_*/
