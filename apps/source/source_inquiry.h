/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2011-2014

PROJECT
    source
    
FILE NAME
    source_inquiry.h

DESCRIPTION
    Inquiry sub-system used to locate discoverable remote devices.
    
*/


#ifndef _SOURCE_INQUIRY_H_
#define _SOURCE_INQUIRY_H_


/* profile/library headers */
#include <connection.h>


/* Inquiry defines */
#define INQUIRY_LAP                 0x9e8b33
#define INQUIRY_MAX_RESPONSES       10
#define INQUIRY_TIMEOUT             4           /* timeout * 1.28 seconds */ 
#define INQUIRY_SCAN_BUFFER_SIZE    10


/* Values used to identify profiles */
typedef enum
{
    PROFILE_NONE   = 0x00,  
    PROFILE_A2DP   = 0x01,
    PROFILE_AGHFP  = 0x02,
    PROFILE_AVRCP  = 0x04,
    PROFILE_ALL    = 0x0f
} PROFILES_T;


/* Inquiry structures */
typedef struct
{    
    int16 path_loss;
    PROFILES_T profiles:4;
    unsigned profiles_complete:1;
} INQUIRY_EIR_DATA_T;


typedef struct
{
    uint16 read_idx;
    uint16 write_idx;
    uint16 search_idx;    
    bdaddr buffer[INQUIRY_SCAN_BUFFER_SIZE];
    INQUIRY_EIR_DATA_T eir_data[INQUIRY_SCAN_BUFFER_SIZE];
    unsigned inquiry_state_timeout:1;
} INQUIRY_SCAN_DATA_T;


typedef struct
{
    unsigned inquiry_tx:8;
    unsigned force_inquiry_mode:1;
} INQUIRY_MODE_DATA_T;


/***************************************************************************
Function definitions
****************************************************************************
*/


/****************************************************************************
NAME    
    inquiry_init

DESCRIPTION
    Initial setup of inquiry states.
    
*/
void inquiry_init(void);


/****************************************************************************
NAME    
    inquiry_write_eir_data

DESCRIPTION
    Write EIR data after reading the local name of the device.
    
*/
void inquiry_write_eir_data(const CL_DM_LOCAL_NAME_COMPLETE_T *data);


/****************************************************************************
NAME    
    inquiry_start_discovery

DESCRIPTION
    Begin the inquiry procedure.
    
*/
void inquiry_start_discovery(void);


/****************************************************************************
NAME    
    inquiry_handle_result

DESCRIPTION
    Process the inquiry result contained in the CL_DM_INQUIRE_RESULT message.
    
*/
void inquiry_handle_result(const CL_DM_INQUIRE_RESULT_T *result);


/****************************************************************************
NAME    
    inquiry_complete

DESCRIPTION
    Inquiry procedure has completed so tidy up any inquiry data.
    
*/
void inquiry_complete(void);


/****************************************************************************
NAME    
    inquiry_has_results

DESCRIPTION
    Determines if any device has been located during the inquiry procedure.
    
RETURNS
    
    
*/
bool inquiry_has_results(void);


/****************************************************************************
NAME    
    inquiry_process_results

DESCRIPTION
    Process the devices located during the inquiry procedure.
    
*/
void inquiry_process_results(void);


#endif /* _SOURCE_INQUIRY_H_ */
