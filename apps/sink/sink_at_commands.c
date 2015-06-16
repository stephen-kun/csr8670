/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2005-2014

FILE NAME
    sink_at_commands.c

DESCRIPTION
    Application level control of AT commands sent and received via the HFP 
    connections. 
    
    These can be configured in 2 ways, 
    received AT commands that ate unrecognised by the HFP library will be passed 
    to the applciation (here)
    
    If these match any of the commands in the cofiguration, then a response also 
    in the configuration will be sent to the AG device. 
    
    Alternatively, User events can be configured to send configured AT commands 
    (from the same list) to the AG on receipt of any user event,
    
    E.g. This allows the user to configure an event that can be sent to the AG on 
    connection or when the battery level changes.

NOTES


*/
/****************************************************************************
    Header files
*/
#include "sink_at_commands.h"
#include "sink_private.h"
#include "sink_config.h"
#include "sink_audio.h"
#include <string.h>


#ifdef DEBUG_AT_COMMANDS
    #define AT_DEBUG(x) DEBUG(x)
#else
    #define AT_DEBUG(x) 
#endif

static const char * const mic_test_string     = "+MICTEST" ;
static const char * const mic_test_string_res_success = "AT+MICTEST=1\r" ;
static const char * const mic_test_string_res_fail = "AT+MICTEST=0\r" ;
static const uint8 battery_scaling_2[] = {0,1,3,5,7,9};

/****************************************************************************
DESCRIPTION
    handles an unrecognised AT command from the HFP library
        
    Attempts to match an AT command to those configured. If configured, a response
    will be sent.
    
    If not configured, a response will not be sent.
    
    If the +MICTEST is configured, the mic test switching will take place
    
    
*/
void sinkHandleUnrecognisedATCmd(HFP_UNRECOGNISED_AT_CMD_IND_T *ind)         
{
    char* pData;
    char* pSearchString = NULL;
    uint16 i = 0 ;
    char *pDataEnd = (char*)(ind->data + ind->size_data);
    
    AT_DEBUG(("HFP_UNRECOGNISED_AT_CMD_IND\n" )) ;
        
    /* Skip to start of AT command */
    for(pData = (char*)ind->data; pData < pDataEnd; pData++)
        if(*pData == '+' || *pData == '-')
            break;
    
    /*remove carriage returns / line feeds at end of AT commands (allows shorter matches in config)*/    
    for (i = 0 ; &pData[i] < pDataEnd && pData[i] != '\0' ;i++)
    {
        if (( pData[i] == 0xd ) || (pData[i] == 0xa ) )
            pData[i] = 0x0 ;
    }
    
    AT_DEBUG(("AT command = %s\n", pData));
    
    if ( strncmp(pData, mic_test_string, strlen(mic_test_string)) == 0 ) 
    {
        AT_DEBUG(("Handle Mic Switch\n"));
        if (audioHandleMicSwitch())
        {
            /* Send the success response AT command */
            AT_DEBUG(("Response %s\n", mic_test_string_res_success));
            HfpAtCmdRequest(ind->priority, mic_test_string_res_success);
        }
        else
        {
            /* Send the failed response AT command */
            AT_DEBUG(("Response %s\n", mic_test_string_res_fail));
            HfpAtCmdRequest(ind->priority, mic_test_string_res_fail);        
        }
    }    
    
    /* check if there's any more configured AT commands to check */
    if(!theSink.conf3)
    {
        AT_DEBUG(("AT: Unrecognised AT Cmd -  no config\n" )) ;
        return;
    }
    
    pSearchString = theSink.conf3->at_commands;
    
    /* Try and match the AT command */
    while(*pSearchString != '\0')
    {
        /* Command followed by response string */
        char* res_string = pSearchString + strlen(pSearchString) + 1;
        AT_DEBUG(("Matching %s\n", pSearchString));
        
        /* If the incoming command matches; handle & respond */
        if(*pData == '+' && strncmp(pData, pSearchString, strlen(pSearchString)) == 0)
        {            
            /* Send the response AT */
            AT_DEBUG(("Response %s\n", res_string));
            HfpAtCmdRequest(ind->priority, res_string);
            break;
        }
        
        /* Move to the next command */
        pSearchString = res_string + strlen(res_string) + 1;
    }
   
}

/****************************************************************************
DESCRIPTION
    Sends a given AT command from the configuration 
        
    works through the configuration looking for '\0' signifying end of string, 
    moves to next string in list until string == '\0'
    
    If a string matching the id passed in, then the command is sent to the AG.
    If not, no command is sent
    
*/
void sinkSendATCmd( uint16 at_id ) 
{
    uint8 count = 0;
    char* search_string = NULL;
    
    if(!theSink.conf3)
    {
        AT_DEBUG(("AT: Send Cmd -  no config\n" )) ;
        return;
    }
    
    search_string = theSink.conf3->at_commands;
        
    AT_DEBUG(("AT: Send Cmd\n" )) ;

    /* get to the nth string if it exists */
    while(*search_string != '\0')
    {
        AT_DEBUG(("String %s\n", search_string));
        
        if (count == at_id )
            break ;

        /* Move to the next command */
        search_string = search_string + strlen(search_string) + 1;
        count++;
    }
    AT_DEBUG(("AT Send:[%s]\n", search_string));
    
    /*only send the string if we actually matched the command*/
    if (count == at_id)
    {
        uint16 i = 0 ;    
    
        char * string_to_send = mallocPanic (strlen(search_string)+1) ;
        
        memset (string_to_send , 0 , strlen(search_string)) ;

        if(string_to_send) strcpy(string_to_send, search_string );

            /*replace any values which need replacing*/
        for (i = 0 ; string_to_send[i] != '\0' ;i++)
        {
            switch (string_to_send[i]) 
            {               
                /* 0x81 - battery reporting scaling of 0,1,2,3,4,5 */
                case battery_0_to_5 :
                /* 0x82 - battery reporting scaling of 0,2,4,6,8,9 */
                case battery_0_to_9_scaling_1 :
                {
                        /*multiply the battery level (0-5) by 1 or 2 to get scale*/
                    power_battery_level batt_lvl = (theSink.battery_state * (string_to_send[i]-0x80))  ;
                    
                        /*crop to max of 9*/
                    if (batt_lvl > 9) batt_lvl = 9 ;

                        /*convert to ascii*/
                    string_to_send[i] = batt_lvl + 0x30 ;
                }  
                break;
                /* 0x83 - battery reporting scaling of 0,1,3,5,7,9 */
                case battery_0_to_9_scaling_2 :
                {
                    /* use scaling of 0,1,3,5,7,9 */
                    power_battery_level batt_lvl = battery_scaling_2[theSink.battery_state] ;
                    /*convert to ascii*/
                    string_to_send[i] = batt_lvl + 0x30 ;                  
                }
                break;
                default:
                break ;
             }
        }
            
        if (string_to_send)
        {            
            HfpAtCmdRequest(hfp_primary_link, string_to_send);
            HfpAtCmdRequest(hfp_secondary_link, string_to_send);
            
            freePanic(string_to_send) ;  
        }    
    }
}


/****************************************************************************
DESCRIPTION
    Checks for a user event -> AT command match configured in CONFIG_USR_3
    If configued, AT command sent to valid HFP connections using 
    sinkSendATCommand
    
    Up to MAX_AT_COMMANDS_TO_SEND AT commands can be stored in the PSKEY 
    for Sending to the AG
    
    An EventSysGasGauge0 or an EventSysChargerGasGauge0 configured will result in the 
    same message being sent for any of the gas gauge events.
    
*/
void ATCommandPlayEvent ( sinkEvents_t id ) 
{
    uint16 i = 0 ;
    
    if(!theSink.conf3)
    {
        AT_DEBUG(("AT: Play Cmd -  no config\n" )) ;
        return;
    }
    
    for (i =0 ; i < MAX_AT_COMMANDS_TO_SEND ; i++ )
    {
        if ( (id) == theSink.conf3->gEventATCommands[i].event )     
        {
            AT_DEBUG(("AT: Ev [%x] AT CMD [%d]" , id , theSink.conf3->gEventATCommands[i].at_cmd )) ;
            
            sinkSendATCmd ( theSink.conf3->gEventATCommands[i].at_cmd ) ;    
        }
        
            /*special handling for gas gauge events */
        switch ( theSink.conf3->gEventATCommands[i].event )
        {
            case EventSysGasGauge0:
                if ( ( id >= EventSysGasGauge0 ) && (id <= EventSysGasGauge3)) 
                {
                    AT_DEBUG(("AT: Ev Gas Gauge n [%x] AT CMD [%d]" , id , theSink.conf3->gEventATCommands[i].at_cmd )) ;
                    sinkSendATCmd ( theSink.conf3->gEventATCommands[i].at_cmd ) ;    
                }
            break ;
            case EventSysChargerGasGauge0:
                if ( ( id >= EventSysChargerGasGauge0 ) && ( id <= EventSysChargerGasGauge3)) 
                {
                    AT_DEBUG(("AT: Ev Charger Gas Gauge n [%x] AT CMD [%d]" , id , theSink.conf3->gEventATCommands[i].at_cmd )) ;
                    sinkSendATCmd ( theSink.conf3->gEventATCommands[i].at_cmd ) ;    
                }
            break ;
            default:
            break ;
        }
        
    }
}


