// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1921919 $  $DateTime: 2014/06/18 21:18:28 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Connection Buffer Library
//
// DESCRIPTION:
//    This library provides an API for dealing with buffers in Kalimba memory
//    (which are called cbuffers) and the MMU ports which stream data between
//    the Bluecore subsystem and the Kalimba.
//
//    An interface is of use since the hardware buffers are a fixed size that
//    is often too small to take a 'frame' of codec data.  Also, data jitter
//    is removed through the use of larger software based buffers.
//
//    Once a cbuffer has been initialised, it may be referenced using its
//    buffer structure alone; the size, read and write pointers are all stored
//    and used appropriately.
//
//    This interface is potentially wasteful in memory since data is,
//    effectively, buffered twice but for most real world applications,
//    for example MP3 decoding, codecs produce data in large chunks that
//    would need to be stored in a temporary buffer.
//
//    Libraries may be written that read or write data to/from a cbuffer
//    and hence provide a standard interface.  These cbuffers may then be
//    connected (using a copying function) to a Kalimba port to transfer
//    the data to the Bluecore subsystem.  During this copying operation,
//    operations such as bit width conversion, DC removal, volume
//    adjustment, filtering and equalisation may be performed using the CBOPS
//    library routines.
//
//    For example, a generic codec decoder library may be written which
//    has 1 cbuffer (the compressed input stream) as input and two
//    cbuffers (stereo audio streams) as outputs.  These cbuffers may then
//    be connected (using copying functions) to Kalimba ports, or perhaps
//    through some other library such as an audio equaliser.
//
// *****************************************************************************
#ifndef CBUFFER_INCLUDED
#define CBUFFER_INCLUDED

#include "stack.h"
#include "cbuffer.h"
#include "message.h"
#include "kalimba_standard_messages.h"
#include "architecture.h"


#ifdef DALE_ON_GORDON
   #ifdef NON_CONTIGUOUS_PORTS
      #undef NON_CONTIGUOUS_PORTS
   #endif
#endif

.MODULE $cbuffer;
   .DATASEGMENT DM;

#ifdef DALE_ON_GORDON
   .BLOCK port_buffer_size;
    .VAR      read_port_buffer_size[8];
    .VAR      write_port_buffer_size[8];
   .ENDBLOCK;
   .BLOCK port_offset_addr;
    .VAR      read_port_offset_addr[8];
    .VAR      write_port_offset_addr[8];
   .ENDBLOCK;
   .BLOCK port_limit_addr;
    .VAR      read_port_limit_addr[8];
    .VAR      write_port_limit_addr[8];
   .ENDBLOCK;
#else
   .BLOCK port_buffer_size;
    .VAR      read_port_buffer_size[$cbuffer.NUM_PORTS];
    .VAR      write_port_buffer_size[$cbuffer.NUM_PORTS];
   .ENDBLOCK;
   .BLOCK port_offset_addr;
    .VAR      read_port_offset_addr[$cbuffer.NUM_PORTS];
    .VAR      write_port_offset_addr[$cbuffer.NUM_PORTS];
   .ENDBLOCK;
   .BLOCK port_limit_addr;
    .VAR      read_port_limit_addr[$cbuffer.NUM_PORTS];
    .VAR      write_port_limit_addr[$cbuffer.NUM_PORTS];
   .ENDBLOCK;
#endif

   .VAR      write_port_connect_address = 0;
   .VAR      write_port_disconnect_address = 0;
   .VAR      read_port_connect_address = 0;
   .VAR      read_port_disconnect_address = 0;
   .VAR      auto_mcu_message = 1;

   .VAR      configure_port_message_struc[$message.STRUC_SIZE];

   .VAR      tmp[2];

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbuffer.initialise
//
// DESCRIPTION:
//    Initialise cbuffer library.
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3
//
// NOTES:
//    Should be called after $message.initialise since it sets up the message
// handler for buffer configuring.
//
// *****************************************************************************
.MODULE $M.cbuffer.initialise;
   .CODESEGMENT CBUFFER_INITIALISE_PM;

   $cbuffer.initialise:

   // push rLink onto stack
   $push_rLink_macro;

   // set up message handers for $MESSAGE_CONFIGURE_PORT message
   r1 = &$cbuffer.configure_port_message_struc;
   r2 = Null OR $MESSAGE_CONFIGURE_PORT;
   r3 = &$cbuffer.configure_port_message_handler;
   call $message.register_handler;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbuffer.is_it_enabled
//
// DESCRIPTION:
//    See if a cbuffer/port is enabled/valid
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//
// OUTPUTS:
//    - Z flag set if the port/cbuffer isn't enabled/valid
//    - Z flag cleared if the port/cbuffer is enabled/valid
//
// TRASHED REGISTERS:
//    r0
//
// *****************************************************************************
.MODULE $M.cbuffer.is_it_enabled;
   .CODESEGMENT CBUFFER_IS_IT_ENABLED_PM;

   $cbuffer.is_it_enabled:

   Null = SIGNDET r0;
   // if its NZ its a cbuffer so exit
   if NZ rts;

   // its a port we need to check if its enabled
   r0 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
   Null = M[$cbuffer.port_offset_addr + r0];
   rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbuffer.get_read_address_and_size
//
// DESCRIPTION:
//    Get a read address and size for a cbuffer/port so that it can read in a
// generic way.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//
// OUTPUTS:
//    - r0 = read address
//    - r1 = buffer size
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//    If passed a pointer to a cbuffer structure then return the value of the
// current read address and size of the cbuffer.
// If passed a port identifier then return the read address for the port, and
// set the size always to 1.
//
//    After having read a block of data a call must be made to
// $cbuffer.set_read_address to actually update the read pointer
// accordingly. E.g.
//    @verbatim
//       // get the read pointer for $my_cbuffer_struc
//       r0 = $my_cbuffer_struc;
//       call $cbuffer.get_read_address_and_size;
//       I0 = r0;
//       L0 = r1;
//
//       // now read some data from it
//       // NOTE: Should already have checked that there is enough data
//       // in the buffer to be able to read these 10 locations, ie.
//       // using $cbuffer.calc_amount_data.
//       r10 = 10;
//       r5 = 0;
//       do sum_10_samples_loop;
//          r1 = M[I0,1];
//          r5 = r5 + r1;
//       sum_10_samples_loop:
//       ....
//
//       // now update the stored pointers
//       r0 = $my_cbuffer_struc;
//       r1 = I0;
//       call $cbuffer.set_read_address;
//    @endverbatim
//
//
// *****************************************************************************
#ifndef BASE_REGISTER_MODE
.MODULE $M.cbuffer.get_read_address_and_size;
   .CODESEGMENT CBUFFER_GET_READ_ADDRESS_AND_SIZE_PM;

   $cbuffer.get_read_address_and_size:

   Null = SIGNDET r0;
   if Z jump $cbuffer.get_read_address_and_size.its_a_port;

   its_a_cbuffer:
      r1 = M[r0 + $cbuffer.SIZE_FIELD];
      r0 = M[r0 + $cbuffer.READ_ADDR_FIELD];
      rts;
.ENDMODULE;
#endif
.MODULE $M.cbuffer.get_read_address_and_size.its_a_port;
   .CODESEGMENT CBUFFER_GET_READ_ADDRESS_AND_SIZE_ITS_A_PORT_PM;

   $cbuffer.get_read_address_and_size.its_a_port:

#ifdef DEBUG_ON
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      Null = r1 - $cbuffer.NUM_PORTS;
      // cannot get a read address for a write port so we error
      if POS call $error;
#endif
      // it's a read port
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      // if force flags are set then alter appropriate config bits for the port
      Null = r0 AND ($cbuffer.FORCE_ENDIAN_MASK + $cbuffer.FORCE_SIGN_EXTEND_MASK + $cbuffer.FORCE_BITWIDTH_MASK + $cbuffer.FORCE_PADDING_MASK);

      if Z jump no_forcing;

         // we need 2 more temp registers so save r2 & r3
         M[$cbuffer.tmp + 0] = r2;
         M[$cbuffer.tmp + 1] = r3;
#ifdef NON_CONTIGUOUS_PORTS
         r2 = ($READ_CONFIG_GAP - 1);
         Null = ($cbuffer.TOTAL_CONTINUOUS_PORTS -1) - r1;
         if NEG  r1 = r1 + r2;
#endif

         // read config register
         r3 = M[r1 + $READ_PORT0_CONFIG];

         // adjust config register if 'forced' endian selected
         r2 = r0 AND $cbuffer.FORCE_ENDIAN_MASK;
         if Z jump no_forcing_endian;
            r3 = r3 AND (65535 - $BYTESWAP_MASK);
            r2 = r2 LSHIFT $cbuffer.FORCE_ENDIAN_SHIFT_AMOUNT;
            r2 = r2 LSHIFT $BYTESWAP_POSN;
            r3 = r3 OR r2;
         no_forcing_endian:

         // adjust config register if 'forced' sign extension selected
         r2 = r0 AND $cbuffer.FORCE_SIGN_EXTEND_MASK;
         if Z jump no_forcing_sign_extend;
            r3 = r3 AND (65535 - $NOSIGNEXT_MASK);
            r2 = r2 LSHIFT $cbuffer.FORCE_SIGN_EXTEND_SHIFT_AMOUNT;
            r2 = r2 LSHIFT $NOSIGNEXT_POSN;
            r3 = r3 OR r2;
         no_forcing_sign_extend:

         // adjust config register if 'forced' bitwidth selected
         r2 = r0 AND $cbuffer.FORCE_BITWIDTH_MASK;
         if Z jump no_forcing_bitwidth;
            r3 = r3 AND (65535 - $BITMODE_MASK);
            r2 = r2 LSHIFT $cbuffer.FORCE_BITWIDTH_SHIFT_AMOUNT;
            r2 = r2 LSHIFT $BITMODE_POSN;
            r3 = r3 OR r2;
         no_forcing_bitwidth:
         
#if defined(RICK)
         // adjust config register if 'forced' padding selected
         r2 = r0 AND $cbuffer.FORCE_PADDING_MASK;
         if Z jump no_forcing_padding;
            r3 = r3 AND (65535 - $PAD_EN_MASK);
            r2 = r2 LSHIFT $cbuffer.FORCE_PADDING_SHIFT_AMOUNT;
            r2 = r2 LSHIFT $PAD_EN_POSN;
            r3 = r3 OR r2;
         no_forcing_padding:
#endif

         // update config register with any 'forces' required
         M[r1 + $READ_PORT0_CONFIG] = r3;

         // restore the saved registers
         r2 = M[$cbuffer.tmp + 0];
         r3 = M[$cbuffer.tmp + 1];
      no_forcing:

      // return the data address of it and a size of 1
      r0 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
#ifdef NON_CONTIGUOUS_PORTS
         r1 =($READ_DATA_GAP - 1);
         Null = ($cbuffer.TOTAL_CONTINUOUS_PORTS -1) - r0;
         if NEG  r0 = r0 + r1;
#endif
      r0 = r0 + $READ_PORT0_DATA;
      r1 = 1;
      rts;

.ENDMODULE;

#ifdef BASE_REGISTER_MODE
// *****************************************************************************
// MODULE:
//    $cbuffer.get_read_address_and_size_and_start_address
//
// DESCRIPTION:
//    Get a read address and size for a cbuffer/port so that it can read in a
// generic way.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//
// OUTPUTS:
//    - r0 = read address
//    - r1 = buffer size
//    - r2 = buffer start address
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//    If passed a pointer to a cbuffer structure then return the value of the
// current read address and size of the cbuffer.
//
// *****************************************************************************
.MODULE $M.cbuffer.get_read_address_and_size_and_start_address;
   .CODESEGMENT CBUFFER_GET_READ_ADDRESS_AND_SIZE_PM;

   $cbuffer.get_read_address_and_size_and_start_address:

   Null = SIGNDET r0;
   if Z jump its_a_port;
      r2 = M[r0 + $cbuffer.START_ADDR_FIELD];
      r1 = M[r0 + $cbuffer.SIZE_FIELD];
      r0 = M[r0 + $cbuffer.READ_ADDR_FIELD];
      rts;

   its_a_port:
      push rLink;
      call $cbuffer.get_read_address_and_size.its_a_port;
      pop rLink;
      r2 = r0;
      rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbuffer.get_write_address_and_size_and_start_address
//
// DESCRIPTION:
//    Get the write address and size for a cbuffer/port so that it can written
// in a generic way.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//
// OUTPUTS:
//    - r0 = write address
//    - r1 = buffer size
//    - r2 = buffer start address
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//    If passed a pointer to a cbuffer structure then return the value of the
//    current write address and size of the cbuffer.
//    If passed a port identifier then return the write address for the port, and
//    set the size always to 1.
//
// *****************************************************************************
.MODULE $M.cbuffer.get_write_address_and_size_and_start_address;
   .CODESEGMENT CBUFFER_GET_WRITE_ADDRESS_AND_SIZE_PM;

   $cbuffer.get_write_address_and_size_and_start_address:

   Null = SIGNDET r0;
   if Z jump its_a_port;

   its_a_cbuffer:
      r2 = M[r0 + $cbuffer.START_ADDR_FIELD];
      r1 = M[r0 + $cbuffer.SIZE_FIELD];
      r0 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
      rts;

   its_a_port:
      push rLink;
      call $cbuffer.get_write_address_and_size.its_a_port;
      pop rLink;
      r2 = r0;
      rts;

.ENDMODULE;


#endif


// *****************************************************************************
// MODULE:
//    $frmbuffer.get_buffer
//	  $frmbuffer.get_buffer_with_start_address
//
// DESCRIPTION:
//    Get frame buffer frame size, ptr,length, and base address
//
// INPUTS:
//    - r0 = pointer to frame buffer structure
//
// OUTPUTS:
//    - r0 = buffer address
//    - r1 = buffer size
//    - r2 = buffer start address   <base address variant>
//    - r3 = frame size
//
// TRASHED REGISTERS:
//    r2 - (not base address variant)
//
// NOTES:
//    Return the buffer start address in r2 if BASE_REGISTER_MODE
//
// *****************************************************************************
.MODULE $M.frmbuffer.get_buffer;
   .CODESEGMENT CBUFFER_FRM_BUFFER_PM;

#ifdef BASE_REGISTER_MODE
$frmbuffer.get_buffer_with_start_address:
#else
$frmbuffer.get_buffer:
#endif
   r3  = M[r0 + $frmbuffer.FRAME_SIZE_FIELD];
   r2  = M[r0 + $frmbuffer.CBUFFER_PTR_FIELD];
   r0  = M[r0 + $frmbuffer.FRAME_PTR_FIELD];
   r1  = M[r2 + $cbuffer.SIZE_FIELD];
#ifdef BASE_REGISTER_MODE
   r2  = M[r2 + $cbuffer.START_ADDR_FIELD];
#endif
   rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $frmbuffer.set_frame_size
//
// DESCRIPTION:
//    Set frame buffer's frame size
//
// INPUTS:
//    - r0 = pointer to frame buffer structure
//    - r3 = frame size
//
// OUTPUTS:
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//
// *****************************************************************************
.MODULE $M.frmbuffer.set_frame_size;
   .CODESEGMENT CBUFFER_FRM_BUFFER_PM;

$frmbuffer.set_frame_size:
   M[r0 + $frmbuffer.FRAME_SIZE_FIELD] = r3;
   rts;
.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbuffer.get_write_address_and_size
//
// DESCRIPTION:
//    Get the write address and size for a cbuffer/port so that it can written
// in a generic way.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//
// OUTPUTS:
//    - r0 = write address
//    - r1 = buffer size
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//    If passed a pointer to a cbuffer structure then return the value of the
//    current write address and size of the cbuffer.
//    If passed a port identifier then return the write address for the port, and
//    set the size always to 1.
//
// *****************************************************************************
#ifndef BASE_REGISTER_MODE
.MODULE $M.cbuffer.get_write_address_and_size;
   .CODESEGMENT CBUFFER_GET_WRITE_ADDRESS_AND_SIZE_PM;

   $cbuffer.get_write_address_and_size:

   Null = SIGNDET r0;
   if Z jump $cbuffer.get_write_address_and_size.its_a_port;

   its_a_cbuffer:
      r1 = M[r0 + $cbuffer.SIZE_FIELD];
      r0 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
      rts;
.ENDMODULE;
#endif
.MODULE $M.cbuffer.get_write_address_and_size.its_a_port;
   .CODESEGMENT CBUFFER_GET_WRITE_ADDRESS_AND_SIZE_ITS_A_PORT_PM;

   $cbuffer.get_write_address_and_size.its_a_port:

   #ifdef DEBUG_ON
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      Null = r1 - $cbuffer.NUM_PORTS;
      // cannot get a write address for a read port so we error
      if NEG call $error;
   #endif
      // it's a write port
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      r1 = r1 - $cbuffer.NUM_PORTS;
      // save r2
      M[$cbuffer.tmp + 0] = r2;
      // if force flags are set then alter appropriate config bits for the port
      Null = r0 AND ($cbuffer.FORCE_ENDIAN_MASK + $cbuffer.FORCE_BITWIDTH_MASK + $cbuffer.FORCE_SATURATE_MASK + $cbuffer.FORCE_PADDING_MASK);
      if Z jump no_forcing;

         // save r3
         M[$cbuffer.tmp + 1] = r3;

#ifdef NON_CONTIGUOUS_PORTS
       r2 = ($WRITE_CONFIG_GAP - 1);
       Null =($cbuffer.TOTAL_CONTINUOUS_PORTS - 1) - r1;
       if NEG  r1 = r1 + r2;
#endif

         // read config register
         r3 = M[r1 + $WRITE_PORT0_CONFIG];

         // adjust config register if 'forced' endian selected
         r2 = r0 AND $cbuffer.FORCE_ENDIAN_MASK;
         if Z jump no_forcing_endian;
            r3 = r3 AND (65535 - $BYTESWAP_MASK);
            r2 = r2 LSHIFT $cbuffer.FORCE_ENDIAN_SHIFT_AMOUNT;
            r2 = r2 LSHIFT $BYTESWAP_POSN;
            r3 = r3 OR r2;
         no_forcing_endian:

         // adjust config register if 'forced' bitwidth selected
         r2 = r0 AND $cbuffer.FORCE_BITWIDTH_MASK;
         if Z jump no_forcing_bitwidth;
            r3 = r3 AND (65535 - $BITMODE_MASK);
            r2 = r2 LSHIFT $cbuffer.FORCE_BITWIDTH_SHIFT_AMOUNT;
#if defined(RICK)
            // is this "24" bit audio mode, we borrow r1 and restore it later
            r1 = ($cbuffer.FORCE_16BIT_WORD >> -$cbuffer.FORCE_BITWIDTH_SHIFT_AMOUNT);
            Null = r2 - ($cbuffer.FORCE_32BIT_WORD >> -$cbuffer.FORCE_BITWIDTH_SHIFT_AMOUNT);
            if Z r2 = r1;
            r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
            r1 = r1 - $cbuffer.NUM_PORTS;
#endif
            r2 = r2 LSHIFT $BITMODE_POSN;
            r3 = r3 OR r2;
         no_forcing_bitwidth:

         // adjust config register if 'forced' saturate selected
         r2 = r0 AND $cbuffer.FORCE_SATURATE_MASK;
         if Z jump no_forcing_saturate;
            r3 = r3 AND (65535 - $SATURATE_MASK);
            r2 = r2 LSHIFT $cbuffer.FORCE_SATURATE_SHIFT_AMOUNT;
            r2 = r2 LSHIFT $SATURATE_POSN;
            r3 = r3 OR r2;
         no_forcing_saturate:

         // update config register with any 'forces' required
         M[r1 + $WRITE_PORT0_CONFIG] = r3;

         // restore the saved registers
         r3 = M[$cbuffer.tmp + 1];

      no_forcing:
      // return the data address of it and a size of 1

#ifdef NON_CONTIGUOUS_PORTS
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      r1 = r1 - $cbuffer.NUM_PORTS;
      r2 = ($WRITE_DATA_GAP - 1);
      Null =($cbuffer.TOTAL_CONTINUOUS_PORTS - 1) - r1;
      if NEG  r1 = r1 + r2;
#endif
     // restore the saved registers
     r2 = M[$cbuffer.tmp + 0];
     r0 = r1 + $WRITE_PORT0_DATA;
     r1 = 1;
     rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbuffer.set_read_address
//
// DESCRIPTION:
//    Set the read address for a cbuffer/port.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//    - r1 = read address
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    If a cbuffer: none
//    If a port: r0, r1, r2, r3, r4, r5, r10, DoLoop
//
// NOTES:
//    If passed a pointer to a cbuffer structure then set the value of the
//    current read address of the cbuffer.
//    If passed a port identifier then set the read offset for the port, and
//    handle other maintainance tasks associated with ports.
//
// *****************************************************************************
.MODULE $M.cbuffer.set_read_address;
   .CODESEGMENT CBUFFER_SET_READ_ADDRESS_PM;

   $cbuffer.set_read_address:

   Null = SIGNDET r0;
   if Z jump $cbuffer.set_read_address.its_a_port;

   its_a_cbuffer:
      M[r0 + $cbuffer.READ_ADDR_FIELD] = r1;
      rts;
.ENDMODULE;

.MODULE $M.cbuffer.set_read_address.its_a_port;
   .CODESEGMENT CBUFFER_SET_READ_ADDRESS_ITS_A_PORT_PM;

   $cbuffer.set_read_address.its_a_port:

   #ifdef DEBUG_ON
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      Null = r1 - $cbuffer.NUM_PORTS;
      // cannot set the read address for a write port so we error
      if POS call $error;
   #endif
      // push rLink onto stack
      $push_rLink_macro;

      r0 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;

      // force an MMU buffer set
      Null = M[$PORT_BUFFER_SET];

      // if requested send message to MCU
      Null = M[$cbuffer.auto_mcu_message];
      if Z jump dont_message_send;

         // if limit_addr is in MCU_WIN1 then the device connected to the port
         // is software triggered and so we should send a DATA_CONSUMED message
         r1 = M[$cbuffer.read_port_limit_addr + r0];
         Null = r1 - $MCUWIN2_START;
         if POS jump dont_message_send;

            // setup message
            r2 = Null OR $MESSAGE_DATA_CONSUMED;
            // r3 = bit mask depending on port number
            r3 = 1 ASHIFT r0;
            call $message.send_short;
      dont_message_send:

      // pop rLink from stack
      jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbuffer.set_write_address
//
// DESCRIPTION:
//    Set the write address for a cbuffer/port.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//    - r1 = write address
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    If a cbuffer: none
//    If a port: r0, r1, r2, r3, r4, r5, r10, DoLoop
//
// NOTES:
//    If passed a pointer to a cbuffer structure then set the value of the
//    current write address of the cbuffer.
//    If passed a port identifier then set the write offset for the port, and
//    handle other maintainance tasks associated with ports.
//
// *****************************************************************************
.MODULE $M.cbuffer.set_write_address;
   .CODESEGMENT CBUFFER_SET_WRITE_ADDRESS_PM;

   $cbuffer.set_write_address:

   Null = SIGNDET r0;
   if Z jump $cbuffer.set_write_address.its_a_port;

   its_a_cbuffer:
      M[r0 + $cbuffer.WRITE_ADDR_FIELD] = r1;
      rts;
.ENDMODULE;

.MODULE $M.cbuffer.set_write_address.its_a_port;
   .CODESEGMENT CBUFFER_SET_WRITE_ADDRESS_ITS_A_PORT_PM;

   $cbuffer.set_write_address.its_a_port:

   #ifdef DEBUG_ON
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      Null = r1 - $cbuffer.NUM_PORTS;
      // cannot set the write address for a read port so we error
      if NEG call $error;
   #endif

      // push rLink onto stack
      $push_rLink_macro;

      r0 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      r0 = r0 - $cbuffer.NUM_PORTS;

      // force an MMU buffer set
      Null = M[$PORT_BUFFER_SET];

      // if requested send message to MCU
      Null = M[$cbuffer.auto_mcu_message];
      if Z jump dont_message_send;

         // if limit_addr is in MCU_WIN1 then the device connected to the port
         // is software triggered and so we should send a DATA_PRODUCED message
         r1 = M[$cbuffer.write_port_limit_addr + r0];
         Null = r1 - $MCUWIN2_START;
         if POS jump dont_message_send;

            // setup message
            r2 = Null OR $MESSAGE_DATA_PRODUCED;
            // r3 = bit mask depending on port number
            r3 = 1 ASHIFT r0;
            call $message.send_short;
      dont_message_send:

      // pop rLink from stack
      jump $pop_rLink_and_rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $cbuffer.calc_amount_space
//
// DESCRIPTION:
//    Calculates the amount of space for new data in a cbuffer/port.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//
// OUTPUTS:
//    - r0 = amount of space (for new data) in words
//    - r2 = buffer size in words (bytes if an mmu port)
//
// TRASHED REGISTERS:
//    r1
//
// NOTES:
//    If passed a pointer to a cbuffer structure then return the amount of space
//    (for new data) in the cbuffer.
//    If passed a port identifier then return the amount of space (for new data)
//    in the port.
//
// *****************************************************************************
.MODULE $M.cbuffer.calc_amount_space;
   .CODESEGMENT CBUFFER_CALC_AMOUNT_SPACE_PM;

   $cbuffer.calc_amount_space:

   Null = SIGNDET r0;
   if Z jump $cbuffer.calc_amount_space.its_a_port;

   its_a_cbuffer:
      r2 = M[r0 + $cbuffer.SIZE_FIELD];
      r1 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
      r0 = M[r0 + $cbuffer.READ_ADDR_FIELD];

      // calculate the amount of space
      r0 = r0 - r1;
      if LE r0 = r0 + r2;

      // always say it's 1 less so that buffer never gets totally filled up
      r0 = r0 - 1;
      rts;
.ENDMODULE;

.MODULE $M.cbuffer.calc_amount_space.its_a_port;
   .CODESEGMENT CBUFFER_CALC_AMOUNT_SPACE_ITS_A_PORT_PM;

   $cbuffer.calc_amount_space.its_a_port:
      // get the port number
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
      r1 = r1 - $cbuffer.NUM_PORTS;

      #ifdef DEBUG_ON
         // cannot get the amount of space for a read port so we error
         if NEG call $error;
      #endif

      r2 = M[$cbuffer.write_port_limit_addr + r1];
      // check port is still valid, otherwise rts
      if Z r0 = 0;
      if Z rts;

      // save r3
      M[$cbuffer.tmp + 0] = r3;

      // get limit offset value
      r3 = M[r2];
      // get the actual MMU offset
      r2 = M[$cbuffer.write_port_offset_addr + r1];
      r2 = M[r2];

      // calculate the amount of space (Limit offset - local write offset)
      r3 = r3 - r2;

      // get buffer size
      r2 = M[$cbuffer.write_port_buffer_size + r1];
      r1 = r2 - 1;

      // mask out wrap around
      r1 = r3 AND r1;

      // if ptrs equal then Space = BufSize
      if Z r1 = r2;

      // always say 1 less so that buffer never gets totally filled up
      r1 = r1 - 1;

      // restore r3
      r3 = M[$cbuffer.tmp + 0];

      // now convert from num_bytes to the correct word size
      r0 = r0 AND $cbuffer.FORCE_BITWIDTH_MASK;
      if Z jump port_width_16bit;
      Null = r0 - $cbuffer.FORCE_16BIT_WORD;
      if Z jump port_width_16bit;
      if NEG jump port_width_8bit;
      Null = r0 - $cbuffer.FORCE_24BIT_WORD;
      if Z jump port_width_24bit;

      port_width_32bit:
         // calc floor(num_bytes / 4)
         r0 = r1 ASHIFT -2;
         rts;

      port_width_24bit:
         // calc floor(num_bytes / 3)
         r0 = r1 - 1;
         // * 0.3333 (16bt precison) so no prefix needed
         r0 = r0 * 0x2AAB00 (frac);
         rts;

      port_width_8bit:
         // calc floor(num_bytes / 1)
         r0 = r1;
         rts;

      port_width_16bit:
         // calc floor(num_bytes / 2)
         r0 = r1 ASHIFT -1;
         rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $cbuffer.calc_amount_data
//
// DESCRIPTION:
//    Calculates the amount of data already in a cbuffer/port.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//
// OUTPUTS:
//    - r0 = amount of data available in words
//    - r1 = amount of data available in bytes (needed for USB support)
//    - r2 = buffer size in words (bytes if an mmu port)
//
// TRASHED REGISTERS:
//    r1
//
// NOTES:
//    If passed a pointer to a cbuffer structure then return the amount of data
//    in the cbuffer.
//    If passed a port identifier then return the amount of data in the port.
//
// *****************************************************************************
.MODULE $M.cbuffer.calc_amount_data;
   .CODESEGMENT CBUFFER_CALC_AMOUNT_DATA_PM;

   $cbuffer.calc_amount_data:

   Null = SIGNDET r0;
   if Z jump $cbuffer.calc_amount_data.its_a_port;

   its_a_cbuffer:
      r2 = M[r0 + $cbuffer.SIZE_FIELD];
      r1 = M[r0 + $cbuffer.WRITE_ADDR_FIELD];
      r0 = M[r0 + $cbuffer.READ_ADDR_FIELD];

      // calculate the amount of data
      r0 = r1 - r0;
      if NEG r0 = r0 + r2;
      rts;
.ENDMODULE;

.MODULE $M.cbuffer.calc_amount_data.its_a_port;
   .CODESEGMENT CBUFFER_CALC_AMOUNT_DATA_ITS_A_PORT_PM;

   $cbuffer.calc_amount_data.its_a_port:
      // get the port number
      r1 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;

      #ifdef DEBUG_ON
          Null = r1 - $cbuffer.NUM_PORTS;
          // cannot get the amount of data available for a write port so we error
          if POS call $error;
      #endif

      r2 = M[$cbuffer.read_port_limit_addr + r1];
      // check port is still valid, otherwise rts
      if Z r0 = 0;
      if Z rts;
      // get limit offset value
      r2 = M[r2];

      // save r3
      M[$cbuffer.tmp + 0] = r3;

      r3 = M[$cbuffer.read_port_offset_addr + r1];
      r3 = M[r3];

      // calculate the amount of data (Limit offset - local read offset)
      r3 = r2 - r3;

      // get buffer size
      r2 = M[$cbuffer.read_port_buffer_size + r1];
      r1 = r2 - 1;

      // mask out any wrap around
      r1 = r3 AND r1;

      // restore r3
      r3 = M[$cbuffer.tmp + 0];

      // now convert from num_bytes to the correct word size
      r0 = r0 AND $cbuffer.FORCE_BITWIDTH_MASK;
      if Z jump port_width_16bit;
      Null = r0 - $cbuffer.FORCE_16BIT_WORD;
      if Z jump port_width_16bit;
      if NEG jump port_width_8bit;
      Null = r0 - $cbuffer.FORCE_24BIT_WORD;
      if Z jump port_width_24bit;

      port_width_32bit:
         // calc floor(num_bytes / 4)
         r0 = r1 ASHIFT -2;
         rts;

      port_width_24bit:
         // calc floor(num_bytes / 3)
         r0 = r1 - 1;
         // * 0.3333 (16bt precison) so no prefix needed
         r0 = r0 * 0x2AAB00 (frac);
         rts;

      port_width_8bit:
         // calc floor(num_bytes / 1)
         r0 = r1;
         rts;

      port_width_16bit:
         // calc floor(num_bytes / 2)
         r0 = r1 ASHIFT - 1;
         rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $cbuffer.buffer_configure
//
// DESCRIPTION:
//    Configures a kalimba cbuffer for use
//
// INPUTS:
//    - r0 = cbuffer structure
//    - r1 = read/write address (ie. initialised to be the same)
//    - r2 = buffer size
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    none
//
// *****************************************************************************
.MODULE $M.cbuffer.buffer_configure;
   .CODESEGMENT CBUFFER_BUFFER_CONFIGURE_PM;

   $cbuffer.buffer_configure:

   M[r0 + $cbuffer.WRITE_ADDR_FIELD] = r1;
   M[r0 + $cbuffer.READ_ADDR_FIELD] = r1;
   M[r0 + $cbuffer.SIZE_FIELD] = r2;
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $cbuffer.configure_port_message_handler
//
// DESCRIPTION:
//    Message handler for $MESSAGE_CONFIGURE_PORT message
//
// INPUTS:
//    - r0 = message ID
//    - r1 = message Data 0  (Port number 0-3 read port, 4-7 write port)
//    - r2 = message Data 1  (Offset address pointer)
//    - r3 = message Data 2  (Limit address pointer)
//    - r4 = message Data 3  (unused)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2
//
// *****************************************************************************
.MODULE $M.cbuffer.configure_port_message_handler;
   .CODESEGMENT CBUFFER_CONFIGURE_PORT_MESSAGE_HANDLER_PM;

   $cbuffer.configure_port_message_handler:

   // push rLink onto stack
   $push_rLink_macro;

   // See if it's a read or write port that's being configured
   Null = r1 - $cbuffer.NUM_PORTS;
   if POS call write_port;

   read_port:
      // ** Configure read port for use by cbuffer functions**
      // r1 = msg_data_1: port number
      // r2 = msg_data_2: offset address
      // r3 = msg_data_3: limit address
      M[$cbuffer.read_port_limit_addr + r1] = r3;
      M[$cbuffer.read_port_offset_addr + r1] = r2;

      // if offset address is zero then port has been disconnected
      if NZ jump read_port_connect;

         r0 = M[$cbuffer.read_port_disconnect_address];
         if NZ call r0;

         // pop rLink from stack
         jump $pop_rLink_and_rts;

      read_port_connect:

      r0 = r1;

      // store buffer size
      r2 = M[r2 + (-1)];                   // buffer size field
      r1 = $cbuffer.MMU_PAGE_SIZE;
      r2 = r2 LSHIFT -8;                   // calc buffer size
      r2 = r1 LSHIFT r2;
      M[$cbuffer.read_port_buffer_size + r0]  = r2;

      // if we're connected to a non-software triggered device (eg DAC/ADC/SCO)
      // then assume we need 16-bit and sign-extension
      r1 = $BITMODE_16BIT_ENUM;

      // if we're connected to a software triggered device (eg UART/L2CAP)
      // then assume we need to byteswap the 16-bit data and not do sign-extension
      r2 = ($BITMODE_16BIT_ENUM + $BYTESWAP_MASK + $NOSIGNEXT_MASK);
      Null = r3 - $MCUWIN2_START;
      if NEG r1 = r2;
#ifdef NON_CONTIGUOUS_PORTS

      push r0;
      push r2;
      r2 =($READ_CONFIG_GAP - 1);
      Null = ($cbuffer.TOTAL_CONTINUOUS_PORTS -1) - r0;
      if NEG  r0 = r0 + r2;
      M[$READ_PORT0_CONFIG + r0] = r1;
      pop r2;
      pop r0;
#else
      M[$READ_PORT0_CONFIG + r0] = r1;
#endif
      // load the port number in r1 & call the connect function if there is one
      r1 = r0;
      r0 = M[$cbuffer.read_port_connect_address];
      if NZ call r0;

      // pop rLink from stack
      jump $pop_rLink_and_rts;


   write_port:
      // ** Configure write port for use by cbuffer functions**
      // r1 = msg_data_1: port number
      // r2 = msg_data_2: offset address
      // r3 = msg_data_3: limit address
      M[($cbuffer.write_port_limit_addr - $cbuffer.WRITE_PORT_OFFSET) + r1] = r3;
      M[($cbuffer.write_port_offset_addr - $cbuffer.WRITE_PORT_OFFSET) + r1] = r2;
      // if offset address is zero then port has been disconnected
      if NZ jump write_port_connect;

         r0 = M[$cbuffer.write_port_disconnect_address];
         if NZ call r0;
         // pop rLink from stack
         jump $pop_rLink_and_rts;

      write_port_connect:

      r0 = r1;

      // store buffer size
      r2 = M[r2 + (-1)];                   // buffer size field
      r1 = $cbuffer.MMU_PAGE_SIZE;
      r2 = r2 LSHIFT -8;                   // calc buffer size
      r2 = r1 LSHIFT r2;
      M[($cbuffer.write_port_buffer_size - $cbuffer.WRITE_PORT_OFFSET) + r0]  = r2;

      // if we're connected to a non-software triggered device (eg DAC/ADC/SCO)
      // then assume we need 16-bit data
      // and also saturate to 16bits
      r1 = ($BITMODE_16BIT_ENUM + $SATURATE_MASK);

      // if we're connected to a software triggered device (eg UART/L2CAP)
      // then assume we need to byteswap the 16-bit data
      r2 = ($BITMODE_16BIT_ENUM + $BYTESWAP_MASK);
      Null = r3 - $MCUWIN2_START;
      if NEG r1 = r2;

#ifdef NON_CONTIGUOUS_PORTS

      push r0;
      push r2;
      r0 = r0 - $cbuffer.NUM_PORTS;
      r2 =($WRITE_CONFIG_GAP -1);
      Null = ($cbuffer.TOTAL_CONTINUOUS_PORTS - 1) - r0;
      if NEG  r0 = r0 + r2;
      M[$WRITE_PORT0_CONFIG + r0] = r1;
      pop r2;
      pop r0;
#else
      M[($WRITE_PORT0_CONFIG - $cbuffer.WRITE_PORT_OFFSET) + r0] = r1;
#endif

      // load the port number in r1 & call the connect function if there is one
      r1 = r0;
      r0 = M[$cbuffer.write_port_connect_address];
      if NZ call r0;

      // pop rLink from stack
      jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $cbuffer.force_mmu_set
//
// DESCRIPTION:
//    Update the MMU offsets
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//    This forces an MMU buffer set.
//
//    Each MMU port has an offset which tracks how much data has been accessed
// from the port. The DSP uses this value to work out how much data/space is
// available in the port.
//
// Kalimba can explicitly force an MMU buffer set. Consequently a local offset
// is not stored in the DSP and the cache will never be stale so long as you
// perform a set after reads and writes - i.e. call
// $cbuffer.set_read_address and $cbuffer.set_write_address.
//
// *****************************************************************************
.MODULE $M.cbuffer.force_mmu_set;
   .CODESEGMENT CBUFFER_FORCE_MMU_SET_PM;

   $cbuffer.force_mmu_set:

   // force an MMU buffer set
   Null = M[$PORT_BUFFER_SET];

   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $cbuffer.empty_buffer
//
// DESCRIPTION:
//    Empties the supplied port or cbuffer.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0 - r3, r10, DoLoop
//
// NOTES:
//    This routine empties a port or cbuffer. For cbuffers it simply moves the
// read pointer, for ports it must read the samples from the port.
//
//    Interrupts should be blocked before this call, unless you "own" the
// cbuffer read pointer.
//
// *****************************************************************************
.MODULE $M.cbuffer.empty_buffer;
   .CODESEGMENT CBUFFER_EMPTY_BUFFER_PM;

   $cbuffer.empty_buffer:

   // push rLink onto stack
   $push_rLink_macro;

   // save r0
   r3 = r0;

   Null = SIGNDET r0;
   if Z jump its_a_port;
      // move the read pointer to the write pointer
      call $cbuffer.get_write_address_and_size;
      r1 = r0;
   jump set_address_and_exit;

   its_a_port:
      // for a port its a bit more work, we actually have to read the data
      // how much data is there
      call $cbuffer.calc_amount_data;
      r10 = r0;
      // get the read address
      r0 = r3;
      call $cbuffer.get_read_address_and_size;

      // go round and read the data
      do empty_port_loop;
         Null = M[r0];
      empty_port_loop:

   set_address_and_exit:
   // update the read address - r1 set if its a cbuffer, r2 if its a port
   r0 = r3;
   call $cbuffer.set_read_address;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $cbuffer.fill_buffer
//
// DESCRIPTION:
//    Fills a port or cbuffer with a supplied value.
//
// INPUTS:
//    - r0 = pointer to cbuffer structure (for cbuffers)
//           or a port identifier (for ports)
//    - r1 = value to write into buffer/port
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0 - r4, r10, I0, L0, DoLoop
//
// NOTES:
//    This routine fills a port or cbuffer with a supplied value.
//
//    Interrupts must be blocked during this call.
//
// *****************************************************************************
.MODULE $M.cbuffer.fill_buffer;
   .CODESEGMENT CBUFFER_FILL_BUFFER_PM;

   $cbuffer.fill_buffer:

   // push rLink onto stack
   $push_rLink_macro;

   // save the inputs
   r3 = r0;
   r4 = r1;

   // work out how much space we've got
   call $cbuffer.calc_amount_space;
   r10 = r0;

   // get the read address and size
   r0 = r3;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;

   // fill the buffer
   do fill_buffer_loop;
      M[I0,1] = r4;
   fill_buffer_loop:

   // set the write address, r2 has already been set (in case its a port)
   r0 = r3;
   r1 = I0;
   call $cbuffer.set_write_address;
   L0 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $cbuffer.advance_read_ptr
//
// DESCRIPTION:
//    Advances read pointer of a cbuffer by a supplied value
//
// INPUTS:
//    - r0 = pointer to cbuffer struc
//    - r10 = number by which read pointer would be advanced
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, I0, L0, M3
//
// NOTES:
//    This routine advances the read pointer of the cbuffer by a supplied value
//
// *****************************************************************************
.MODULE $M.cbuffer.advance_read_ptr;
   .CODESEGMENT CBUFFER_ADVANCE_READ_PTR_PM;

   $cbuffer.advance_read_ptr:

   // push rLink onto stack
   $push_rLink_macro;

   // push r0 onto stack
   push r0;

   // get cbuffer read address and size
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push B0;
   push r2;
   pop  B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I0 = r0;
   L0 = r1;

   // advance read pointer by r10
   M3 = r10;
   r0 = M[I0,M3];

#ifdef BASE_REGISTER_MODE
   pop  B0;
#endif
   // pop r0 from the stack
   pop  r0;

   // set advanced read address
   r1 = I0;
   call $cbuffer.set_read_address;
   L0 = 0;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

#endif

