/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_send_data.c

DESCRIPTION
    

NOTES

*/


/****************************************************************************
    Header files
*/
#include "hfp.h"
#include "hfp_private.h"
#include "hfp_link_manager.h"
#include "hfp_send_data.h"
#include "hfp_common.h"

#include <panic.h>
#include <string.h>
#include <util.h>
#include <print.h>
#include <sink.h>

/*lint -e525 -e830 */

/* 
    getBytesToFlush

    Returns the number of bytes to flush. Iterates to the end of the next AT+ cmd 
    and returns the number of bytes counted.
*/
static uint16 getBytesToFlush(hfp_link_data* link, const uint8 *data_ptr, const uint8 *endptr)
{
    uint16 ix = 0;    

    /* Return zero if the buffer is empty */
    if (data_ptr == endptr)
        return 0;

    /* Find the next AT+ cmd*/
    while ((data_ptr+ix) != endptr)
    {
        if (hfpMatchChar(data_ptr+ix, endptr, 'A'))
        {
            /* Extract the pending_cmd ID and put back the 'T' */
            uint8* mod_ptr            = (uint8*)(data_ptr + ix + 1);
            link->at_cmd_resp_pending = *mod_ptr;
            *mod_ptr                  = (uint8)'T';
            
            PRINT(("Sending AT Command 0x%X ", link->at_cmd_resp_pending));
            PRINT(("%c%c",(char)*(data_ptr+ix), (char)*(data_ptr+ix+1)));
            
            ix+=2;
            
            /* Insert latest requested volume into pending AT+VGS command */
            if(link->at_cmd_resp_pending == hfpVgsCmdPending)
            {
                /* Assumption here is that command is formatted as "AT+VGS=00" */
                mod_ptr  = (uint8*)(data_ptr+ix+5);
                *mod_ptr = '0' + link->at_vol_setting / 10;
                mod_ptr += 1;
                *mod_ptr = '0' + link->at_vol_setting % 10;
                
                /* Reset the vol setting we no longer have a cmd pending */
                link->at_vol_pending = FALSE;
            }
            
            /* Found the start of an AT cmd, now find the end */
            while(((data_ptr+ix) != endptr) && (*(data_ptr+ix) != '\r'))
            {
                PRINT(("%c", (char)*(data_ptr+ix)));
                ix++;
            }
            
            PRINT(("\n"));
            return (ix+1);
        }

        /* Increment the index and carry on looking */
        ix++;
    }

    return (ix+1);
}


/****************************************************************************
NAME    
    hfpSendAtCmd

DESCRIPTION
    Send an AT command by putting it into the RFCOMM buffer.

RETURNS
    void
*/
void hfpSendAtCmd(hfp_link_data* link, uint16 length, const char *at_cmd, hfp_at_cmd pending_cmd)
{
    uint16 sink_slack;
    Sink sink = PanicNull(hfpGetLinkSink(link));
    
    /* Check sink is valid */
    if ( SinkIsValid(sink) )
    {
        /* Get the amount of available space left in the sink */
        sink_slack = SinkSlack(sink);
    
        /* Make sure we have enough space for this AT cmd */
        if (sink_slack >= length)
        {
            uint16 sink_offset = SinkClaim(sink, length);
            uint8 *data_out = SinkMap(sink);
    
            /* Check we have a valid offset */
            if (sink_offset == 0xffff)
            {
                /* The sink offset returned is invalid */
                HFP_DEBUG(("Invalid sink offset\n"));
            }
    
            /* Check we've got a valid data ptr */
            if (data_out)
            {
#ifdef HFP_DEBUG_LIB
                uint16 i;
                PRINT(("Send AT Command 0x%X ", pending_cmd));
                for(i=0; i<length; i++)
                    PRINT(("%c",at_cmd[i]));
#endif
                /* Copy the data into the buffer */
                memmove(data_out+sink_offset, at_cmd, length);
                
                /* Overwrite the 'T' with pending_cmd ID */
                *(data_out+sink_offset+1) = pending_cmd;
                
                /* Try to send the next AT cmd in the buffer if possible */
                hfpSendNextAtCmd(link, SinkClaim(sink, 0), data_out);
            }
            else
            {
                /* SinkMap returned an invalid data ptr. */
                HFP_DEBUG(("Invalid sink ptr\n"));
            }
        }
        else
        {
            /* Not enough space in the rfcomm buffer. */
            HFP_DEBUG(("Insufficient space in sink\n"));
        }
    }
    else
    {
        /* Can happen if disconnecting in hfp_slc_connected state */
        PRINT(("AT Command 0x%X not sent - sink invalid\n", pending_cmd));
    }
}


/****************************************************************************
NAME    
    hfpSendNextAtCmd

DESCRIPTION
    Attempt to send the next AT cmd (if any) pending in the RFCOMM buffer.

RETURNS
    void
*/
void hfpSendNextAtCmd(hfp_link_data* link, uint16 offset, const uint8 *data_out)
{
    Sink sink = hfpGetLinkSink(link);
    
    if ( SinkIsValid(sink) )
    {
        /* Check we have a valid offset */
        if (offset == 0xffff)
        {
            /* The sink offset returned is invalid */
            HFP_DEBUG(("Invalid sink offset\n"));
        }
    
        /* Check we have something to send */
        if (link->at_cmd_resp_pending == hfpNoCmdPending && data_out)
        {
            /* Make sure we have an AT cmd to flush */
            uint16 bytes = getBytesToFlush(link, data_out, data_out+offset);
    
    #ifdef BE_EVIL
            uint16 ix = 0;
            for (ix=0; ix < bytes; ix++)
            {
                (void) SinkFlush(sink, 1);
            }
    #else
            if (bytes)
            {
                /* Flush them. */
                uint16 flush_result = SinkFlush(sink, bytes);
    
                /* Flush failed */
                if (!flush_result)
                    HFP_DEBUG(("Sink flush failed\n")); 
            } /*lint !e548 */
    #endif
    
            /* If we've just sent an AT cmd reset the timeout */
            if (link->at_cmd_resp_pending != hfpNoCmdPending)
            {
                /* Get the timeout ID for this link */
                MessageId timeout_message = hfpGetLinkTimeoutMessage(link, HFP_INTERNAL_WAIT_AT_TIMEOUT_LINK_0_IND);
                
                /* Set short default timeout */
                uint32 timeout = (uint32) AT_RESPONSE_TIMEOUT_5SEC;
                
                /* Cancel any existing timeout messages */
                (void) MessageCancelAll(&theHfp->task, timeout_message);
                
                switch(link->at_cmd_resp_pending)
                {
                    case hfpCnumCmdPending:
                        /* Set long timeout - AT+CNUM has just been sent */
                        timeout = (uint32) AT_RESPONSE_TIMEOUT_10SEC;
                    break;
                    case hfpBinpCmdPending:
                        timeout = (uint32) AT_RESPONSE_TIMEOUT_30SEC;
                    break;
                    default:
                    break;
                }
                
                MessageSendLater(&theHfp->task, timeout_message, 0, timeout);
            }
        }
#ifdef HFP_DEBUG_LIB
        else
        {
            PRINT(("AT Command Blocked by 0x%X\n", link->at_cmd_resp_pending));
        }
#endif
    }
}

/*lint +e525 +e830 */
