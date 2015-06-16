// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#include "spi_comm_library.h"
#include "stack.h"

.MODULE $M.spi_block;
   .DATASEGMENT DM1_SPI_FIXED_BLOCK;
   // constants
   .CONST SPI_CLR          0x5555;
   .CONST SPI_SET          0xAAAA;

   // Message Block
   .BLOCK SPI_BLOCK;
   .VAR signature[5]= 4412242, 2114390, 4399171, 5197396, 5394252;
   .VAR payload[64];
   .VAR command;
   .VAR cmd_ready = SPI_SET;
   .VAR cmd_complete = SPI_CLR;
   .VAR cmd_status = SPI_CLR;
   .VAR cmd_length;
   .ENDBLOCK;
.ENDMODULE;

.MODULE $M.spi_comm;
   .DATASEGMENT DM;

   // set the maximum possible number of handlers - this is only used to detect
   // corruption in the linked list, and so can be quite large
   .CONST   MAX_MESSAGE_HANDLERS       50;
   // flag to imply end of linked list
   .CONST   LAST_ENTRY                 -1;
   // Version
   .VAR Version = SPI_COMM_VERSION;
   // Handler Linked List
   .VAR last_addr = LAST_ENTRY;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $spi_comm.initialise
//
// DESCRIPTION:
//    Initialise spi message system. We set the cmd_ready flag in the spi block
//    to be equal to SPI CLEAR.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.spi_comm.initialize;
   .CODESEGMENT SPI_COMM_INITIALIZE_PM;
$spi_comm.initialize:
   // Signal Ready for Commands
   r0 = $M.spi_block.SPI_CLR;
   M[$M.spi_block.cmd_ready] = r0;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spi_comm.register_handler
//
// DESCRIPTION:
//    Register a message handler function
//
// INPUTS:
//    - r1 = pointer to a variable that stores the message handler structure,
//         should be of length $spi_comm.STRUC_SIZE
//    - r2 = message ID
//    - r3 = message handler address for this message ID
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2 , r3
//
// NOTES:
//  It updates the message handler linked list by updating the last_addr and
//  next_addr fields in the spi_comm data structure to point to appropriate
//  message handlers.
// *****************************************************************************
.MODULE $M.spi_comm.register_handler;
   .CODESEGMENT SPI_COMM_REGISTER_HANDLER_PM;
$spi_comm.register_handler:
   // push rLink onto stack
   $push_rLink_macro;
   // set the next address field of this structure to the previous last_addr
   r0 = M[$M.spi_comm.last_addr];
   M[r1 + $spi_comm.NEXT_ADDR_FIELD] = r0;
   // set new last_addr to the address of this structure
   M[$M.spi_comm.last_addr] = r1;
   // store new entry's ID and handler address in this structre
   M[r1 + $spi_comm.ID_FIELD] = r2;
   M[r1 + $spi_comm.HANDLER_ADDR_FIELD] = r3;
   // pop rLink from stack
   jump $pop_rLink_and_rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $spi_comm.polled_service_routine
//
// DESCRIPTION:
//    Poll communication block for new command and call handler
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    all registsers
//
// Note:
//    should be called in main processing loop as interupts are not blocked
// *****************************************************************************
.MODULE $M.spi_comm.polled_service_routine;
   .CODESEGMENT SPI_COMM_POLLED_SERVICE_ROUTINE_PM;
$spi_comm.polled_service_routine:
   // Check for Command
   r0 = $M.spi_block.SPI_SET;
   NULL = r0 - M[$M.spi_block.cmd_ready];
   if NZ rts;
   // push rLink onto stack
   $push_rLink_macro;
   // Process Command
   r10 = $M.spi_comm.MAX_MESSAGE_HANDLERS;
   r1 = M[$M.spi_comm.last_addr];
   r0 = M[$M.spi_block.command];
   r7 = $M.spi_block.SPI_SET;
   do loop;
      // if we're at the last structure in the linked list then this message
      // ID is unknown
      Null = r1 - $M.spi_comm.LAST_ENTRY;
      if Z jump no_handler;
      // see if ID's matches
      r2 = M[r1 + $spi_comm.ID_FIELD];
      Null = r0 - r2;
      if Z jump found;
      // read the adddress of the next profiler
      r1 = M[r1 + $spi_comm.NEXT_ADDR_FIELD];
loop:
   // something's gone wrong - either too many handlers,
   // or more likely the linked list has got corrupt.
   call $error;
found:
   // lookup address of handler
   rLink = M[r1 + $spi_comm.HANDLER_ADDR_FIELD];
   // now call the handler
   // r0 = command
   // I0 = command data pointer
   // r1 = command data length
   r1 = &$M.spi_block.payload;
   r2 = M[$M.spi_block.cmd_length];
   call rLink;
   r7 = $M.spi_block.SPI_CLR;
no_handler:
   // Clear Command/ Set Completion
   r0 = $M.spi_block.SPI_CLR;
   r1 = $M.spi_block.SPI_SET;
   M[$M.spi_block.cmd_length] = r8;
   M[$M.spi_block.cmd_status] = r7;
   M[$M.spi_block.cmd_ready] = r0;
   M[$M.spi_block.cmd_complete] = r1;
   jump $pop_rLink_and_rts;
.ENDMODULE;

