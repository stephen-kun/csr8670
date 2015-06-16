// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef MESSAGE_HEADER_INCLUDED
#define MESSAGE_HEADER_INCLUDED

#include "architecture.h"

   // Kalimba uses a software queue to store messages the MCU hasn't yet
   // acknowledged. The queue holds long and short messages, and its size is
   // defined in terms of the largest long message that can be sent.

   // set the max long message payload sizes for send and receive
   .CONST   $message.MAX_LONG_MESSAGE_TX_PAYLOAD_SIZE  80;
   .CONST   $message.MAX_LONG_MESSAGE_RX_PAYLOAD_SIZE  80;


   // allow for ID and size
   .CONST   $message.MAX_LONG_MESSAGE_TX_SIZE          ($message.MAX_LONG_MESSAGE_TX_PAYLOAD_SIZE + 2);
   .CONST   $message.MAX_LONG_MESSAGE_RX_SIZE          ($message.MAX_LONG_MESSAGE_RX_PAYLOAD_SIZE + 2);

   // we can't fill the queue so max messages = (QUEUE_SIZE_IN_MSGS - 1)
   .CONST   $message.QUEUE_SIZE_IN_MSGS                (($message.MAX_LONG_MESSAGE_TX_SIZE+3)>>2)+1;

   // calculate send queue and receive buffer sizes
   .CONST   $message.QUEUE_SIZE_IN_WORDS               ($message.QUEUE_SIZE_IN_MSGS * (1+4));
   .CONST   $message.LONG_MESSAGE_BUFFER_SIZE          (((($message.MAX_LONG_MESSAGE_RX_SIZE+3)>>2)+1) * 4);

   // set the maximum possible number of handlers - this is only used to detect
   // corruption in the linked list, and so can be quite large
   .CONST   $message.MAX_MESSAGE_HANDLERS       50;



   // set the timer period after which to reattempt sending a message to the MCU
   // if it hasn't yet acknowledged the previous message
   .CONST   $message.REATTEMPT_SEND_PERIOD      1000;

   // tell message library which shared memory locations to use
   .CONST   $message.TO_DSP_SHARED_WIN_SIZE     4;
   .CONST   $message.TO_MCU_SHARED_WIN_SIZE     4;
   .CONST   $message.ACK_FROM_MCU               ($MCUWIN1_START + 0);
   .CONST   $message.ACK_FROM_DSP               ($MCUWIN1_START + 1);
   .CONST   $message.DATA_TO_MCU                ($MCUWIN1_START + 2);
   .CONST   $message.DATA_TO_DSP                ($MCUWIN1_START + 2 + $message.TO_DSP_SHARED_WIN_SIZE);

   // flag to imply end of linked list
   .CONST   $message.LAST_ENTRY                -1;

   // special ID to imply long message mode
   .CONST   $message.LONG_MESSAGE_MODE_ID      -2;

   // message handler structure fields
   .CONST   $message.NEXT_ADDR_FIELD            0;
   .CONST   $message.ID_FIELD                   1;
   .CONST   $message.HANDLER_ADDR_FIELD         2;
   .CONST   $message.MASK_FIELD                 3;
   .CONST   $message.STRUC_SIZE                 4;

   // number of words in each message
   .CONST   $message.QUEUE_WORDS_PER_MSG        (1+4);

 #endif
