// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef SPI_COMM_LIB_H
#define SPI_COMM_LIB_H

// *****************************************************************************
// NAME:
//    SPI_COMM Library
//
// DESCRIPTION:
//    This library provides CSR's implementation of the SPI communication to the
//    DSP 
//    
//    The library provides the following routines:
//
//    The library version is available at the data location:
//      $M.spi_comm.Version
//
// *****************************************************************************

//  SPI Communications Library version number
.CONST   $SPI_COMM_VERSION      0x010000;   //1.0

// message handler structure fields
.CONST   $spi_comm.NEXT_ADDR_FIELD     0;
.CONST   $spi_comm.ID_FIELD            1;
.CONST   $spi_comm.HANDLER_ADDR_FIELD  2;
.CONST   $spi_comm.STRUC_SIZE          3;

// *****************************************************************************
// MODULE:
//    $spi_comm.initialise
//
// DESCRIPTION:
//    Initialise spi message system
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
//    r0, r1
//
// *****************************************************************************


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
// *****************************************************************************

// *****************************************************************************
// MODULE:
//    message handler
//
// DESCRIPTION:
//    User registered message handler
//
// INPUTS:
//    r0 - command ID
//   r1 - Command/Response data pointer
//   r2 - command data length 
// OUTPUTS:
//    r8 - response data length
//
// *****************************************************************************

#endif
