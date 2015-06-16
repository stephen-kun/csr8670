/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2009-2014
Part of ADK 3.5

FILE NAME
    avrcp_avctp.c

DESCRIPTION
    Functions in this file handles AVCTP protocol transactions and 
    AVCTP message handling. All function prototypes are defined in 
    avrcp_signal_handler.h

NOTES

*/


/****************************************************************************
    Header files
*/
#include <Stream.h>
#include <Sink.h>
#include <Source.h>
#include <Panic.h>
#include <memory.h>
#include "avrcp_common.h"
#include "avrcp_browsing_handler.h"

#define VALID_PID(PTR,IDX) (((PTR)[(IDX)]==AVCTP1_PROFILE_AVRCP_HIGH) && ((PTR)[(IDX)+1]==AVCTP2_PROFILE_AVRCP_REMOTECONTROL))

/****************************************************************************
*NAME    
*    avrcpAvctpHandleBadPacket    
*
*DESCRIPTION
*   This function is called to handle bad packet while processing a AVCTP 
*   packet. If the packet is an incoming command, AVCTP sends out a response
*   Otherwise it ignores the packet.
*    
*PARAMETERS
*   avrcp         - Task
*   ptr           - packet
*   cr_type       - Command / Response
*
*RETURN
*******************************************************************************/
static void avrcpAvctpBadPacketHandler(AVRCP *avrcp, 
                                 const uint8 *ptr,
                                       uint16 packet_len,
                                       uint8  cr_type)
{
#ifndef AVRCP_CT_ONLY_LIB /* Disable TG for CT only lib */
    if(cr_type == AVCTP0_CR_COMMAND)
    {
        avrcp->av_msg = (uint8*)ptr;
        avrcp->av_msg_len = packet_len;
        avrcpSendAvcResponse(avrcp, AVRCP_START_PKT_HEADER_SIZE, 
                                   avctp_response_rejected, 0, NULL);
    }
    else
#endif /* AVRCP_CT_ONLY_LIB */
        SourceDrop(StreamSourceFromSink(avrcp->sink), packet_len);
}

#ifndef AVRCP_TG_ONLY_LIB /* Disable CT for TG only lib */
/****************************************************************************
*NAME    
*    avrcpAvctpSetCmdHeader    
*
*DESCRIPTION
*    This function is called to set the AVCTP header for START or SINGLE Packet
*    for commands.For Continue or End Packet call the Macro 
*    AVCTP_SET_PKT_HEADER.
*    
*PARAMETERS
*   avrcp         - Task
*   *ptr          - Pointer to the Start of AVCTP Packet in Sink 
*   packet_type   - MUST be AVCTP0_PACKET_TYPE_SINGLE/AVCTP0_PACKET_TYPE_START.
*   total_packets - Total Number of Packets
*
*RETURN
*******************************************************************************/
void avrcpAvctpSetCmdHeader(AVRCP *avrcp, 
                            uint8 *ptr, 
                            uint8 packet_type, 
                            uint8 total_packets)
{
    /* AVCTP header */
    ptr[0] = (avrcpGetNextTransactionLabel(avrcp) << AVCTP0_TRANSACTION_SHIFT)
             | packet_type | AVCTP0_CR_COMMAND;
    if (packet_type == AVCTP0_PACKET_TYPE_SINGLE)
    {
        ptr[1] = AVCTP1_PROFILE_AVRCP_HIGH;
        ptr[2] = AVCTP2_PROFILE_AVRCP_REMOTECONTROL;
    }
    else if (packet_type == AVCTP0_PACKET_TYPE_START)
    {
        ptr[1] = total_packets;
        ptr[2] = AVCTP1_PROFILE_AVRCP_HIGH;
        ptr[3] = AVCTP2_PROFILE_AVRCP_REMOTECONTROL;
    }
}

#endif /* !AVRCP_TG_ONLY_LIB */


/****************************************************************************
*NAME    
*    avrcpAvctpSendMessage    
*
*DESCRIPTION
*    This function is called to Frame the AVCTP messages (Command or Response)
*   and send it to the peer. Before calling this function, fill the AVRCP 
*   Message  Header in the sink. For sending a response, copy the AVCTP 
*   header received to *ptr before calling the function. Set the Profile ID 
*   in the response. Set the hdr_size=0 (no avrcp header) for
*   bad_profile response.   
*    
*PARAMETERS
*   avrcp            - Task
*   cr_type          - set to 0 for command and 2 for response    
*   ptr              - Pointer to the Start of AVCTP Packet in Sink 
*   hdr_size         - Header size of AVRCP message already in the sink 
*   data_len         - Length of AVRCP message data to send
*   data             - AVRCP Message data to append after AVRCP message head    
*
*RETURN
*   avrcp_status_code
*******************************************************************************/

avrcp_status_code avrcpAvctpSendMessage( AVRCP     *avrcp,
                                         uint8      cr_type,
                                         uint8     *ptr,
                                         uint16     hdr_size,
                                         uint16     data_len,
                                         Source     data)   
{
    uint8  avctp_pkt_type = AVCTP0_PACKET_TYPE_SINGLE;
    uint8  i, start_head;
    uint8  no_complete_packets=0;
    uint16 msg_len=data_len;
    uint16 pkt_size = hdr_size+data_len+AVCTP_SINGLE_PKT_HEADER_SIZE;
    avrcp_status_code result = avrcp_success;
    Sink sink=avrcp->sink;

    /* 
     * Check the packet size is greater than L2CAP MTU Size. Fragmentation is 
     * required for AVCTP packets greater than MTU Size
     */
    if(pkt_size >  avrcp->l2cap_mtu)
    {
        avctp_pkt_type = AVCTP0_PACKET_TYPE_START;
    }

    if(avctp_pkt_type ==  AVCTP0_PACKET_TYPE_START)
    {
        msg_len = avrcp->l2cap_mtu - (hdr_size + AVCTP_START_PKT_HEADER_SIZE);

        /* Calculate the Number of complete_packets.*/
        no_complete_packets = ((data_len - msg_len ) / 
                           (avrcp->l2cap_mtu - AVCTP_CONT_PKT_HEADER_SIZE)) +1;

        /* If there is a reminder of bytes add 1 more */
        if((data_len - msg_len ) % 
            (avrcp->l2cap_mtu - AVCTP_CONT_PKT_HEADER_SIZE))
            no_complete_packets++;
    
        /* Packet size */
        pkt_size = avrcp->l2cap_mtu ;

        /* Fill no_complete_packets to the header */
        ptr[AVCTP_NUM_PKT_OFFSET] = no_complete_packets;
    }

    /* Fill the AVCTP Header */
    if(cr_type == AVCTP0_CR_COMMAND)
    {
        /* Frame the AVCTP header for command. no_complete_packets required
           for start packet is already filled in the header. For a
           Target only library this code is unreachable. */
        avrcpAvctpSetCmdHeader( avrcp,
                                 &ptr[AVCTP_HEADER_START_OFFSET],
                                  avctp_pkt_type, 
                                  no_complete_packets);
    }
    else
    { 
        /* Complete the AVCTP header for response. no_complete_packets and
           PID are already populated. For a Controller only library, this
           code is unreachable. */
        ptr[AVCTP_HEADER_START_OFFSET] =
            (ptr[AVCTP_HEADER_START_OFFSET] & AVCTP_TRANSACTION_MASK) | 
            avctp_pkt_type | AVCTP0_CR_RESPONSE;

        
        /* Set Bad Profile if there is no AVRCP header to follow */
        if(!hdr_size)
        {
            ptr[AVCTP_HEADER_START_OFFSET] |= AVCTP0_IPID;
        } 

    }

    /* Store first octet for future */
    start_head = ptr[AVCTP_HEADER_START_OFFSET];

    /* Before calling this function , Sink Space must be checked for 
     * first message If StreamMove() fails, Target may not get the 
     * entire data and it may drop 
     */
      
    if(msg_len)
    {
        StreamMove(sink, data, msg_len);

        /* Reduce the data length */
        data_len -= msg_len;
    }

    /* Send the data */
    (void)SinkFlush(sink, pkt_size);

    /* Send the rest of AVCTP fragments. Start with 2 since we already sent 1 */
    for (i = 2 ; i <= no_complete_packets; i++)
    {
        if(!(ptr= avrcpGrabSink(sink, AVCTP_CONT_PKT_HEADER_SIZE)))
        {
            result = avrcp_no_resource;
            break;
        }
        
        if(i < no_complete_packets)
        {
            AVCTP_SET_CONT_PKT_HEADER(ptr[AVCTP_HEADER_START_OFFSET],
                                      start_head);
            msg_len = avrcp->l2cap_mtu - AVCTP_CONT_PKT_HEADER_SIZE;
        }
        else
        {
            AVCTP_SET_END_PKT_HEADER(ptr[AVCTP_HEADER_START_OFFSET],start_head);
            msg_len = data_len;
            pkt_size = msg_len + AVCTP_END_PKT_HEADER_SIZE;
        }

        /*  Copy the data to Sink. Sink Space must be validated 
            before calling this function.*/
        StreamMove(sink, data , msg_len); 

           /* Send the data */
        (void)SinkFlush(sink, pkt_size);

        data_len -= msg_len;
    }

    /* If Still Data to send in Source. Drop that much data */
    if (data_len)
    {
        SourceDrop(data,data_len);
    }

    return result;
}

static void removeFragments (AVRCP *avrcp)
{
    if((avrcp->fragment != avrcp_packet_type_single) && avrcp->av_msg_len)
    {
        free(avrcp->av_msg);
        avrcp->av_msg_len = 0;
        avrcp->av_msg = NULL;
        avrcp->fragment = avrcp_packet_type_single; /* Only fragmented packets use a malloc'd data area */
    }
}

/****************************************************************************
*NAME    
*    avrcpAvctpReceiveMessage    
*
*DESCRIPTION
*    This function is called to process the AVCTP message received. 
*    
*PARAMETERS
*   avrcp                  - Task
*   * ptr                  - Received Data
*   packet_size            - packet_size
*
*RETURN
*  bool - Return TRUE if the message is ready to process, otherwise return 
*         FALSE
******************************************************************************/
bool avrcpAvctpReceiveMessage(  AVRCP          *avrcp,
                                const uint8*    ptr,
                                uint16          packet_size)
{
    bool    result = FALSE;
    uint16  packet_type = ptr[AVCTP_HEADER_START_OFFSET] & AVCTP0_PACKET_TYPE_MASK;
    uint8   cr_type = ptr[AVCTP_HEADER_START_OFFSET] & AVCTP0_CR_MASK; 


    switch (packet_type)
    {
    case AVCTP0_PACKET_TYPE_SINGLE: /* Fall through */
        if (packet_size < AVRCP_TOTAL_HEADER_SIZE)
        {   /* Bad Packet. Drop it */
            SourceDrop(StreamSourceFromSink(avrcp->sink), packet_size);
            break;
        }

        /* Drop any partially reconstructed message fragments */
        removeFragments( avrcp );

        /* Check the PID Values */
        if (!VALID_PID( ptr, AVCTP_SINGLE_PKT_PID_OFFSET ))
        {
        #ifndef AVRCP_CT_ONLY_LIB /* Disable TG for CT only lib */
            if(cr_type == AVCTP0_CR_COMMAND)
            {
                avrcp->av_msg = (uint8*)ptr;
                avrcp->av_msg_len = packet_size;
                avrcpSendAvcResponse(avrcp,0,avctp_response_bad_profile, 0, NULL);
            }
            else
        #endif /* AVRCP_CT_ONLY_LIB */
            {
                SourceDrop(StreamSourceFromSink(avrcp->sink), packet_size);
            }
            break;
        }

        avrcp->av_msg = (uint8 *)ptr;
        avrcp->av_msg_len = packet_size;
        avrcp->fragment = avrcp_packet_type_single;
        result = TRUE;
        break;

    case AVCTP0_PACKET_TYPE_START:
        if (packet_size < AVRCP_START_PKT_HEADER_SIZE)
        {   /* Bad Packet. Drop it */
            SourceDrop(StreamSourceFromSink(avrcp->sink), packet_size);
            break; 
        }

        /* Check remote device is planning to send a Message greater than 
           AV Size */
     
        /* Fragmentation is accepted only for Pass through Vendor 
           unique commands, Group Navigation , Vendor specific and
           AVC Commands. 
           Minimum length is AVCTP Start Header of 4 + Vendor ID / Vendor specific header size of 10 */  /* TODO: This comment looks wrong */
        if( (((ptr[AVCTP_NUM_PKT_OFFSET]-1) * avrcp->l2cap_mtu) > AVRCP_AVC_MAX_PKT_SIZE) || 
            (ptr[AVCTP_NUM_PKT_OFFSET] <= 1) ||
            (packet_size < AVRCP_AVC_START_HEADER_SIZE) )
        {
            avrcpAvctpBadPacketHandler(avrcp, ptr, packet_size, cr_type);
            break;   
        }

        /* Drop any partially reconstructed message fragments */
        removeFragments( avrcp );

        /* Check the PID Values */
        if (!VALID_PID( ptr, AVCTP_START_PKT_PID_OFFSET ))
        {
        #ifndef AVRCP_CT_ONLY_LIB /* Disable TG for CT only lib */
            if(cr_type == AVCTP0_CR_COMMAND)
            {
                avrcp->av_msg = (uint8*)ptr;
                avrcp->av_msg_len = packet_size;
                avrcpSendAvcResponse(avrcp,0,avctp_response_bad_profile, 0, NULL);
            }
            else
        #endif /* AVRCP_CT_ONLY_LIB */
            {
                SourceDrop(StreamSourceFromSink(avrcp->sink), packet_size);
            }
            break;
        }

        /* Begin reconstruction of fragmented message, off source */
        avrcp->av_msg = (uint8 *)PanicNull(malloc( packet_size ));
        memmove(avrcp->av_msg, ptr, packet_size);
        avrcp->av_msg_len = packet_size;
        
        /* Reduce the number of expected fragments */
        avrcp->av_msg[AVCTP_NUM_PKT_OFFSET]--;
        avrcp->fragment = avrcp_packet_type_start;
        
        /* Drop message fragment as it has been copied to a separate area for reconstruction */
        SourceDrop(StreamSourceFromSink(avrcp->sink), packet_size);
        break;

    case AVCTP0_PACKET_TYPE_CONTINUE:
    case AVCTP0_PACKET_TYPE_END:  
        if((avrcp->av_msg_len == 0) || (packet_size < AVCTP_CONT_PKT_HEADER_SIZE) || (avrcp->av_msg[AVCTP_NUM_PKT_OFFSET] == 0))
        {   /* Bad Packet. Drop it */
            SourceDrop(StreamSourceFromSink(avrcp->sink), packet_size );
            break;
        }

        /* Check the transaction ID */
        if((ptr[AVCTP_HEADER_START_OFFSET] & AVCTP_TRANSACTION_MASK) != (avrcp->av_msg[AVCTP_HEADER_START_OFFSET] & AVCTP_TRANSACTION_MASK))
        {
            avrcpAvctpBadPacketHandler(avrcp, (const uint8*)avrcp->av_msg, packet_size, cr_type);
            break;
        }

        /* Continue to re-assemble fragmented packet, off source.  Skip over 3 byte AVCTP header when copying data */
        avrcp->av_msg = (uint8 *)PanicNull(realloc(avrcp->av_msg, avrcp->av_msg_len + packet_size - AVCTP_CONT_PKT_HEADER_SIZE));
        memmove(avrcp->av_msg + avrcp->av_msg_len, ptr + AVCTP_CONT_PKT_HEADER_SIZE, packet_size - AVCTP_CONT_PKT_HEADER_SIZE);
        avrcp->av_msg_len += (packet_size - AVCTP_CONT_PKT_HEADER_SIZE);
        
        /* Reduce the number of expected fragments */
        avrcp->av_msg[AVCTP_NUM_PKT_OFFSET]--;
        
        if((packet_type == AVCTP0_PACKET_TYPE_END) || (avrcp->av_msg[AVCTP_NUM_PKT_OFFSET] == 0))
        {   /* Last fragment received */
            avrcp->fragment = avrcp_packet_type_end;
            result = TRUE;
        }
        else
        {   /* More fragments to come */
            avrcp->fragment = avrcp_packet_type_continue;
        }

        /* Drop message fragment as it has been copied to a separate area for reconstruction */
        SourceDrop(StreamSourceFromSink(avrcp->sink), packet_size);
        break;
        
    default:
       /* Bad Packet. Drop it */
       SourceDrop(StreamSourceFromSink(avrcp->sink), packet_size );
       break;
    }

    return result;
}

/****************************************************************************
 *NAME    
 *   avbpAvctpProcessHeader  
 *
 *DESCRIPTION
 *  Validate and process the AVCTP header data in the received packet.
 *
 * PARAMETES
 * AVBP*        - Browsing Task
 * uint8*       - pointer to AVCTP packet
 * uint16       - packet_size
 *
 * RETURN
 * bool - FALSE on Failure and TRUE on Success
 ***************************************************************************/

bool avbpAvctpProcessHeader(    AVBP            *avbp, 
                                const uint8     *ptr, 
                                uint16          packet_size)
{
    if(packet_size < AVCTP_SINGLE_PKT_HEADER_SIZE)
    {
        return FALSE;
    }

    /* parse AVCTP Header*/
    if((ptr[AVCTP_HEADER_START_OFFSET] & AVCTP0_CR_MASK)
                                        == AVCTP0_CR_COMMAND)
    {
       /* Validate the PID Value for incoming command*/
        if((ptr[AVCTP_SINGLE_PKT_PID_OFFSET]!= AVCTP1_PROFILE_AVRCP_HIGH) ||
           (ptr[AVCTP_SINGLE_PKT_PID_OFFSET+1] != 
                                           AVCTP2_PROFILE_AVRCP_REMOTECONTROL)) 
        {
            uint8 *pid_err=avrcpGrabSink(avbp->avbp_sink,
                                         AVCTP_SINGLE_PKT_HEADER_SIZE);

            if(pid_err)
            {
                memmove(pid_err, ptr, AVCTP_SINGLE_PKT_HEADER_SIZE);
                pid_err[AVCTP_HEADER_START_OFFSET] |= AVCTP0_IPID | 
                                                      AVCTP0_CR_RESPONSE;
                (void)SinkFlush(avbp->avbp_sink,AVCTP_SINGLE_PKT_HEADER_SIZE);
            }
            return FALSE;
        }
    }
    else
    {
        /* Match the Outstanding Transaction ID */
        if((ptr[AVCTP_HEADER_START_OFFSET] >> AVCTP0_TRANSACTION_SHIFT) !=
             avbp->trans_id)
        {
            AVRCP_INFO(("TRANSID Mismatch\n"));
            return FALSE;
        }

        if(ptr[AVCTP_HEADER_START_OFFSET] & AVCTP0_IPID)
        {
            AVRCP_INFO(("PID Error\n"));
            avbpSetChannelOnIncomingData(avbp, AVRCP_INVALID_PDU_ID, 0);
            return FALSE;
        }
    }

    /* Set the Outstanding Transaction ID now */
    avbp->trans_id = ptr[AVCTP_HEADER_START_OFFSET] >> AVCTP0_TRANSACTION_SHIFT;

    return TRUE;
}


/****************************************************************************
 *NAME    
 *   avbpAvctpFrameHeader   
 *
 *DESCRIPTION
 *   Frame the AVCTP Header for Browsing packet
 *
 *PARAMETERS
 * AVBP     - Browsing Task 
 * uint8*   - Pointer to the Start of the claimed sink
 * bool     - TRUE if it is response
 ***************************************************************************/
void avbpAvctpFrameHeader(AVBP *avbp, uint8 *ptr , bool response)
{

    if(response)
    {
        ptr[AVCTP_HEADER_START_OFFSET] =  AVCTP0_CR_RESPONSE;        
    }
    else
    {
       ptr[AVCTP_HEADER_START_OFFSET] =  AVCTP0_CR_COMMAND;
    
        /* get Next Transaction ID */
       if(!(avbp->trans_id++))
       {
            avbp->trans_id = 1;
       }    
    }
 
    ptr[AVCTP_HEADER_START_OFFSET] |= (avbp->trans_id << 
                                       AVCTP0_TRANSACTION_SHIFT);
    ptr[AVCTP_SINGLE_PKT_PID_OFFSET] = AVCTP1_PROFILE_AVRCP_HIGH;
    ptr[AVCTP_SINGLE_PKT_PID_OFFSET+1] = AVCTP2_PROFILE_AVRCP_REMOTECONTROL;
}

