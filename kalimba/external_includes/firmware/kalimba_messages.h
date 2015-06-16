/* *****************************************************************************
   Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
   Part of ADK 3.5

   $Revision$  $Date$
   *****************************************************************************

   *****************************************************************************
   NAME:
      kalimba_message.h

   DESCRIPTION:
      Messages passed between BlueCore firmware and the Kalimba DSP.

      Short messages consist of a 16-bit ID and up to four 16-bit arguments.

      Long messages are built up from a number of short messages, see the
      description below under KAL_MSG_PART_BASE.

      If the top-bit of the ID is set the message is routed to the firmware,
      otherwise it is given to the VM application.

      These are simple #define's (converted to .CONSTS for kalimba) since they
      need to be used by the kalimba assembler for the DSP side of things.

   NOTES:
      Port numbers are handled in a rather inconsistent manner. In this file:
      * "read port" is a port sending data to the Kalimba. They are numbered
        from 0 upwards (0..3 on BC3-MM, 0..7 on BC5-MM onwards).
      * "write port" is a port taking data from the Kalimba. They are also
        numbered from 0 upwards (0..3 on BC3-MM, 0..7 on BC5-MM onwards).
      * "either type of port" means either a read port or a write port.
        + Read port numbers are used unchanged.
        + Write port numbers are offset by NUM_PORTS (the number of read ports),
          (so they are 4..7 on BC3-MM, 8..15 on BC5-MM onwards).
      * "biased read port" or "biased write port" means a port of that type
        encoded in the same way as "either type of port".
   *****************************************************************************
*/

#ifndef _KALIMBA_MESSAGES_H
#define _KALIMBA_MESSAGES_H

/*
  Kalimba Ready

  DSP -> FW

  Indicates that the message library in the DSP has successfully
  started and is ready to accept messages from the XAP.
*/
.CONST $MESSAGE_KALIMBA_READY                0x8000;



/*
  Configure port

  FW -> DSP

  Indicate that a DSP port has been configured. Sent from the firmware
  to tell the DSP that a port has just been associated with a buffer
  with the given read and write handles.

  Arguments

    port       Number of either type of port.
    offset     pointer in DSP space to the offset for access
               (owned by the DSP), zero if the port is being
               disconnected.
               (16 bits; to be sign-extended by DSP on devices
               with 24-bit addresses.)
    limit      pointer in DSP space to the limit on the offset
               (updated by Xap), zero if the port is being
               disconnected.
               (16 bits; to be sign-extended by DSP on devices
               with 24-bit addresses.)
    metadata   0: no metadata attached
               1: metadata attached
               All other values are reserved at present.
*/
.CONST $MESSAGE_CONFIGURE_PORT               0x8001;



/*
  Data consumed

  DSP -> FW

  Indicate that data has been consumed through the specified ports and
  the firmware may want to try refilling it.

  Arguments

    ports      bit N set if data consumed on read port N
*/
.CONST $MESSAGE_DATA_CONSUMED                0x8002;



/*
  Data produced

  DSP -> FW

  Indicate that data has been written through the specified ports and
  the firmware may want to try processing it.

  Arguments

    port       bit N set if data produced on write port N
*/
.CONST $MESSAGE_DATA_PRODUCED                0x8003;



/*
  DAC warp

  DSP -> FW

  Adjust warp for one or both DACs.

  Arguments

    which     1 for A, 2 for B, 3 for A&B
    warp      warp to use
*/
.CONST $MESSAGE_WARP_DAC                     0x8004;



/*
  ADC warp

  DSP -> FW

  Adjust warp for ADCs.

  Arguments

    which     0x01 for A, 
              0x02 for B, and 0x03 for A&B
              0x04 for C, 
              0x08 for D, and 0x0C for C&D
              0x10 for E, 
              0x20 for F,  and 0x30 for E&F
              
    warp      warp to use
*/
.CONST $MESSAGE_WARP_ADC                     0x8005;



/*
  Read persistent store

  DSP->FW

  Request the value of a persistent store key

  Arguments

    key      the key to read, as passed to PsFullRetrieve
*/
.CONST $MESSAGE_PS_READ                      0x8006;



/*
  Result of a read from persistent store

  FW->DSP

  Returns the value of a persistent store key (as a long message)

  The maximum size of key which can be read is limited to 64 words
  (63 in older firmware; see B-60183).

  A key which does not exist is read as if it had zero length.

  Arguments
    len      length of this message, including key and value
    key      the key which was read
    value    the words of the key's value
*/
.CONST $LONG_MESSAGE_PS_RESULT               0x8007;



/*
  Indication of a failed read from persistent store

  FW->DSP

  Indicates that the result of a read could not be returned
  because resources on BlueCore were limited. It may be
  possible to try the read again later.

  Arguments
    key      the key which failed to be read
*/
.CONST $MESSAGE_PS_FAIL                      0x8008;



/*
  Find physical flash address for a file

  DSP <-> FW

  Asks the firmware for the physical flash address for a given
  file specified by a FILE_INDEX. Any name to index lookup must
  be performed by the VM application.

  The same message number will be sent back, with the address
  supplied (or zero as the address if an error occurred.)

  Arguments

    index      the index of the file whose address we want
    low_addr   the lower 16 bits of the address (response only)
    high_addr  the upper 16 bits of the address (response only)
*/
.CONST $MESSAGE_FILE_ADDRESS                 0x8009;


/*
  OLD WALLCLOCK MESSAGES THAT ARE NO LONGER SUPPORTED

  These messages are not supported in 26 firmware and above; see B-97150.
  Replacement messages are provided further down this file.

  Request wall clock

  DSP->FW

  Request a wall clock from the firmware. This clock will be the
  same on both ends of a link (the link associated with the
  supplied Bluetooth address.) The clock will also have a
  timestamp from the chip's microsecond timer indicating when
  it was valid.

  Arguments
    word 0 - bits 47:32 of BDADDR
    word 1 - bits 31:16 of BDADDR
    word 2 - bits 15:0 of BDADDR

.CONST $MESSAGE_GET_WALL_CLOCK               0x800A;

  Response to KAL_MSG_GET_WALL_CLOCK

  FW->DSP

  Note: this must be sent as a long message

  Arguments
    word 0 - bits 47:32 of BDADDR
    word 1 - bits 31:16 of BDADDR
    word 2 - bits 15:0 of BDADDR
    word 3 - MS 16bits of clock
    word 4 - LS 16bits of clock
    word 5 - MS 16bits of TIMER_TIME when the clock value was valid
    word 6 - LS 16bits of TIMER_TIME when the clock value was valid

.CONST $LONG_MESSAGE_WALL_CLOCK_RESPONSE          0x800B;

  Response to KAL_MSG_GET_WALL_CLOCK indicating an error

  FW->DSP

  Arguments
    word 0 - bits 47:32 of BDADDR
    word 1 - bits 31:16 of BDADDR
    word 2 - bits 15:0 of BDADDR

.CONST $MESSAGE_WALL_CLOCK_FAILED            0x800C;

*/


/*
  Read Random numbers

  DSP->FW

  Request the random numbers from firmware

  Arguments

    word0    Size of random numbers to read (in bits)
    word1    Request ID of the random number request
*/
.CONST $MESSAGE_RAND_REQ                      0x800D;



/*
  Result of a random number request

  FW->DSP

  Returns the random numbers (as a long message)

  The maximum size of random numbers that can be returned is
  firmware's internal constant (e.g., 128 bits). If requested size is
  greater than this maximum limit then returned size is trimmed to
  this limit.

  Arguments
    len      length of this message, includes :-
                                Returned size
                                Req ID
                                Value:Random numbers
    Size     Number of random numbers returned (in bits)
    Req Id   Returns the same Request ID that was received
    Value    Sequence of random numbers
*/
.CONST $LONG_MESSAGE_RAND_RESULT               0x800E;



/*
  Indication of a failed read for random numbers

  FW->DSP

  Indicates that the result of a request could not be returned
  because an error in BlueCore. It may be possible to try the read 
  again later.

  Arguments
    Req ID      Request ID as received in the request
*/
.CONST $MESSAGE_RAND_FAIL                      0x800F;


/*
  Message to set Kalimba software watchdog

  DSP->FW

  Receipt of this by the firmware starts a one-shot
  timer; if another KAL_MSG_WATCHDOG_SET is not sent
  within that time, the firmware assumes that the DSP
  application has crashed. Currently this triggers a
  VM message MESSAGE_KALIMBA_WATCHDOG_EVENT to any
  registered Kalimba task, if the VM is present.

  The DSP can send this message with a delay of 0 to
  cancel any existing timer.

  Arguments
    Delay      Timeout in milliseconds (0 = disable)
*/
.CONST $MESSAGE_WATCHDOG_SET                     0x8010;

/*
  OLD SNIFF TIME REQUEST MESSAGES THAT ARE NO LONGER SUPPORTED

  These messages are not supported in 26 firmware and above; see B-97150.
  Replacement messages are provided further down this file.

  Request the time of the next sniff anchor point 

  DSP->FW


  Arguments
    word 0 - bits 47:32 of BDADDR
    word 1 - bits 31:16 of BDADDR
    word 2 - bits 15:0 of BDADDR

.CONST $MESSAGE_GET_NEXT_SNIFF_TIME            0x8011;

  Response to KAL_MSG_GET_NEXT_SNIFF_TIME

  FW->DSP

  Note: this must be sent as a long message

  Arguments
    word 0 - bits 47:32 of BDADDR
    word 1 - bits 31:16 of BDADDR
    word 2 - bits 15:0 of BDADDR
    word 3 - MS 16bits of clock
    word 4 - LS 16bits of clock

.CONST $LONG_MESSAGE_GET_NEXT_SNIFF_TIME_RESPONSE   0x8012;

  Response to KAL_MSG_GET_NEXT_SNIFF_TIME indicating an error

  FW->DSP

  Arguments
    word 0 - bits 47:32 of BDADDR
    word 1 - bits 31:16 of BDADDR
    word 2 - bits 15:0 of BDADDR

.CONST $MESSAGE_GET_NEXT_SNIFF_TIME_FAILED     0x8013;

*/

/*
  Request SCO parameters for the specified port

  DSP->FW

  Arguments
    word 0 - either type of port number
*/
.CONST $MESSAGE_GET_SCO_PARAMS          0x8014;


/*
  SCO parameters for a port
  This will be sent when triggered by a KAL_MSG_GET_SCO_PARAMS
  but is also sent asynchronously whenever the SCO connection
  is renegotiated.

  FW->DSP

  Note: this must be sent as a long message

  Arguments
    word 0 - either type of port number
    word 1 - Tesco, in slots
    word 2 - Wesco, in slots
    word 3 - to-air packet length, in bytes
    word 4 - from-air packet length, in bytes
    word 5/6 - wall clock value for the start of the first
               reserved slot (MSW in 5, LSW in 6)
    word 7 - to-air processing time required by firmware, in us
    word 8 - from-air processing time required by firmware, in us
  (Words 7 and 8 indicate how much margin, relative to the start
   of the reserved slot, that the DSP needs to allow when sending
   or reading the data.)
*/
.CONST $LONG_MESSAGE_SCO_PARAMS_RESULT 0x8015;


/*
  Response to KAL_MSG_GET_SCO_PARAMS indicating an error

  FW->DSP

  Arguments
    word 0 - either type of port number
*/
.CONST $MESSAGE_GET_SCO_PARAMS_FAILED   0x8016;


/*
  Indicate that a port requires frame-based semantics

  DSP->FW

  Arguments
    word 0 - biased write port number
    word 1 - frame length (0 = use sample-based logic)
*/
.CONST $MESSAGE_SET_FRAME_LENGTH 0x8017;


/*
  Get the BT address corresponding to a port

  DSP->FW

  Arguments
    word 0 - either type of port number
*/
.CONST $MESSAGE_GET_BT_ADDRESS 0x8018;


/*
  Response to KAL_MSG_GET_BT_ADDRESS

  FW->DSP

  Arguments
    word 0 - 
        bits 0:6  - either type of port number
        bit 7     - set on failure
        bits 8:15 - type field of typed BDADDR
    word 1 - bits 47:32 of BDADDR
    word 2 - bits 31:16 of BDADDR
    word 3 - bits 15:0 of BDADDR
*/
.CONST $MESSAGE_PORT_BT_ADDRESS 0x8019;
#define KAL_GET_BT_ADDRESS_FAILED (1 << 7)

/*
  Response to KAL_MSG_SET_FRAME_LENGTH

  DSP->FW

  Arguments
    word 0 - biased write port number
    word 1 - non-zero for success, zero for failure
*/
.CONST $MESSAGE_FRAME_LENGTH_RESPONSE 0x801A;

/*
  Request wall clock (typed Bluetooth address)

  DSP->FW; new in 26 firmware

  Request a wall clock from the firmware. This clock will be the
  same on both ends of a link (the link associated with the
  supplied Bluetooth address.) The clock will also have a
  timestamp from the chip's microsecond timer indicating when
  it was valid.

  Arguments
    word 0 - type of BDADDR; top 8 bits must be zero
    word 1 - bits 47:32 of BDADDR
    word 2 - bits 31:16 of BDADDR
    word 3 - bits 15:0 of BDADDR
*/
.CONST $MESSAGE_GET_WALL_CLOCK_TBTA  0x801B;


/*
  Response to KAL_MSG_GET_WALL_CLOCK_TBTA

  FW->DSP; new in 26 firmware

  Note: this must be sent as a long message

  Arguments
    word 0 - type of BDADDR
    word 1 - bits 47:32 of BDADDR
    word 2 - bits 31:16 of BDADDR
    word 3 - bits 15:0 of BDADDR
    word 4 - MS 16bits of clock
    word 5 - LS 16bits of clock
    word 6 - MS 16bits of TIMER_TIME when the clock value was valid
    word 7 - LS 16bits of TIMER_TIME when the clock value was valid
*/
.CONST $LONG_MESSAGE_WALL_CLOCK_RESPONSE_TBTA  0x801C;


/*
  Response to KAL_MSG_GET_WALL_CLOCK_TBTA indicating an error

  FW->DSP; new in 26 firmware

  Arguments
    word 0 - type of BDADDR
    word 1 - bits 47:32 of BDADDR
    word 2 - bits 31:16 of BDADDR
    word 3 - bits 15:0 of BDADDR
*/
.CONST $MESSAGE_WALL_CLOCK_FAILED_TBTA  0x801D;

/*
  Request the time of the next activity (sniff anchor point on BR/EDR,
  <to be defined - see B-98155> on BLE).

  DSP->FW; new in 26 firmware

  Arguments
    word 0 - type of BDADDR; top 8 bits must be zero
    word 1 - bits 47:32 of BDADDR
    word 2 - bits 31:16 of BDADDR
    word 3 - bits 15:0 of BDADDR
*/
.CONST $MESSAGE_GET_NEXT_ACTIVITY_TIME  0x801E;

/*
  Response to KAL_MSG_GET_NEXT_ACTIVITY_TIME

  FW->DSP

  Note: this must be sent as a long message; new in 26 firmware

  Arguments
    word 0 - type of BDADDR
    word 1 - bits 47:32 of BDADDR
    word 2 - bits 31:16 of BDADDR
    word 3 - bits 15:0 of BDADDR
    word 4 - MS 16bits of clock
    word 5 - LS 16bits of clock
*/
.CONST $LONG_MESSAGE_GET_NEXT_ACTIVITY_TIME_RESPONSE  0x801F;


/*
  Response to KAL_MSG_GET_NEXT_ACTIVITY_TIME indicating an error

  FW->DSP; new in 26 firmware

  Arguments
    word 0 - type of BDADDR
    word 1 - bits 47:32 of BDADDR
    word 2 - bits 31:16 of BDADDR
    word 3 - bits 15:0 of BDADDR
*/
.CONST $MESSAGE_GET_NEXT_ACTIVITY_TIME_FAILED  0x8020;


/*
   Request a change in PIO ownership.

   DSP->FW; new in 26 firmware

   Arguments
     word 0 - mask of affected PIOs ( 0 to 15)
     word 1 - requested PIO states  ( 0 to 15)
     word 2 - mask of affected PIOs (16 to 31)
     word 3 - requested PIO states  (16 to 31)

   For each PIO, the mask bit should be 1 to change the ownership, and the
   state bit should be 1 to give control of the PIO to the Kalimba or 0 to give
   control to the rest of the system.

   Note:
     If we ever have to deal with more than 32 PIOs, this message can
     be made a long message and the short/long type and the length will
     let the firmware know how many PIOs were involved.
*/
.CONST $MESSAGE_CHANGE_PIO_OWNERSHIP  0x8021;


/*
   Response to KAL_MST_CHANGE_PIO_OWNERSHIP

   FW->DSP; new in 26 firmware

   Arguments
     word 0 - unavailable PIOs    ( 0 to 15)
     word 1 - current PIO states  ( 0 to 15)
     word 2 - unavailable PIOs    (16 to 31)
     word 3 - current PIO states  (16 to 31)

   For each PIO, the "unavailable" bit will be 1 if the request was rejected
   because this PIO was not allowed to be changed (this could happen even if
   the requested state was the same as the current state), and the state bit
   will be 1 if the Kalimba currently has control of the PIO.
*/
.CONST $MESSAGE_PIO_OWNERSHIP_RESPONSE  0x8022;

/* Not documented yet; WIP; Reserve ID on mainline */
.CONST $MESSAGE_CONFIGURE_BITSERIALISER  0x8023;


/*
   Request that the USB charging current be limited (or prevented)
   The DSP might be asserting a PIO which causes some external circuitry to
   consume extra current from the power source. 
   The firmware needs to be aware of this since it may be enabling the
   charger circuitry (USB bus).There are spec limits on the current that can be
   drawn over a USB bus. This message from the DSP can influence the XAP's
   decision to use internal or extrernal charge mode, or to prevent charging
   altogether.

   DSP->FW; new in VULTAN firmware

   Arguments
     word 0 - BOOL prevent-external-charger
     word 1 - BOOL disable-charging-altogether
*/
.CONST $MESSAGE_CHARGER_LIMIT_CURRENT_USE 0x8024;


/* Not documented yet: WIP; Reserve ID on mainline */
.CONST $MESSAGE_CONFIGURE_QPWM              0x8025;

/* Not documented on mainline. Vultan specific message */
.CONST $MESSAGE_CONFIGURE_XIO                0x8026;


/*
   Request for low latency access to the XAP registers.

   DSP->FW;

   The first argument is the approximate interval, in milliseconds,
   that the Kalimba would like the shared memory updated.
   Zero means that the indicated registers are no longer required.
   The other arguments are code numbers (see Kalimba_xap_to_copy.h)
   representing registers and zero means "no register" which doesn't
   generate an entry in the reply.
   All addresses are in Kalimba space and implicitly sign-extended.

   Messages are either short messages (for up to 3 registers) or
   long messages.

   Arguments
     word 0 - Interval at which the registers requires update
     word 1 - Register code number 1
     word 2 - Register code number 2
     word 3 - Register code number 3
     word 4 - Register code number 4
     word 5 - Register code number 5
*/
.CONST $MESSAGE_REGISTER_COPIES_REQUEST      0x8027;

/*
   Response to KAL_MSG_REGISTER_COPIES_REQUEST

   FW->DSP;

   If the request had N registers then the reply has 2N arguments.
   The first N arguments are the addresses where the requested register
   values will be found (so argument 1 is the address corresponding to the
   register specified in argument 2). A zero value means that the XAP is
   unable to provide updates for that register. The last N arguments are
   the addresses of status records relevant to the registers (two or more
   registers may share a status record), or a error code if the XAP is
   unable to provide updates. Error codes are defined under
   kalimba_xap_to_copy.h

   If the KAL_MSG_REGISTER_COPIES_REQUEST request had a zero interval then
   the reply has no arguments

   Messages are either short messages (for up to 2 registers) or
   long messages.

   Arguments
     word 0 - Address of Register code number 1 if successful otherwise zero
     word 1 - Address of Register code number 2 if successful otherwise zero
     word 2 - Address of Register code number 3 if successful otherwise zero
     word 3 - Address of Register code number 4 if successful otherwise zero
     word 4 - Address of Register code number 5 if successful otherwise zero
     :
     :
     word N - Addr of status words for R1 if successful, else error code
     word N+1 - Addr of status words for R2 if successful, else error code
     word N+2 - Addr of status words for R3 if successful, else error code
     word N+3 - Addr of status words for R4 if successful, else error code
     word N+4 - Addr of status words for R5 if successful, else error code
     :
*/
.CONST $MESSAGE_REGISTER_COPIES_REPLY      0x8028;

/*
   Alert message for register copies

   FW->DSP;

   This message is sent as a result of firmware internal activities and also
   (with event 1) in response to a KAL_MSG_REGISTER_COPIES_REQUEST with an
   interval of 0 that means that no registers (not just those in the request)
   are being monitored. It is not sent in response to a
   KAL_MSG_REGISTER_COPIES_REQUEST with a non-zero interval.
   Alert message values are defined under kalimba_xap_to_copy.h

   Argument
   Word 0 - Following are the values
   value  Description
    0      Ignore
    1      All register values are now invalid and there is no point in
           monitoring for change
    2      One or more registers are now being updated
*/
.CONST $MESSAGE_REGISTER_COPIES_ALERT      0x8029;

/* Not documented on mainline. Vultan specific message  
   The DSP can request a bitserial bus switch using short message.

   Arguments
     word 0 - Bus ID
   
*/
.CONST $MESSAGE_BITSERIAL_BUS_SWITCH         0x802A;


/*
  Audio Stream Rate Event

  FW->DSP

  Indicates the rate of the Audio stream. This was primarily required
  for SPDIF stream.

  Arguments
    word 0 - Number of ports(n)

    word 1 : n - port list

    word n + 1 - Lower 16 bits of Sample Rate.

    word n + 2 - Upper 16 bits of Sample Rate.
*/
.CONST $MESSAGE_AUDIO_STREAM_RATE_EVENT     0x802B;

/*
  SPDIF Rx Channel Status

  FW->DSP

  Sends the 12 words of  SPDIF Rx channel status

  Arguments
    word 0 - Number of ports(n)

    word 1 to n - port list

    word (n + 1) to (n + 12) - SPDIF Rx channel status.
*/
.CONST $MESSAGE_SPDIF_CHNL_STS_EVENT     0x802C;

/*
  Configure command from DSP to audio

  DSP->FW

  Arguments
    word 0 - DSP port number

    word 1 - Parameter to be configured

    word 2/3 - New value of parameter (LSW in 2, MSW in 3)

*/
.CONST $MESSAGE_AUDIO_CONFIGURE     0x802D;

/*
  Response to KAL_MSG_AUDIO_CONFIGURE

  FW->DSP

  Arguments
    word 0 - port number
    word 1 - non-zero for success, zero for failure
*/
.CONST $MESSAGE_AUDIO_CONFIGURE_RESPONSE 0x802E;

/*
  Activate/Deactivate audio Hardware

  DSP->FW

  Arguments
    word 0 - DSP port number

    word 1 - 0x00 : Deactivate
             0x01 : Activate

*/
.CONST $MESSAGE_ACTIVATE_AUDIO     0x802F;

/*
  Response to KAL_MSG_ACTIVATE_AUDIO

  FW->DSP

  Arguments
    word 0 - port number
    word 1 - non-zero for success, zero for failure
*/
.CONST $MESSAGE_ACTIVATE_AUDIO_RESPONSE 0x8030;

/*
  SPDIF Block Start Event

  FW->DSP

  Indicates the SPDIF Block Start has been received.

  Arguments
    word 0 - Number of ports(n)

    word 1 : n - port list
*/
.CONST $MESSAGE_SPDIF_BLOCK_START_EVENT     0x8031;

/*
  The following messages are used by Baton.
*/

.CONST $MESSAGE_BATON_BASE      0x9000;
.CONST $MESSAGE_BATON_LIMIT     0x91FF;

/*
   Request an immediate panic.

   DSP->FW.

   No arguments.

   Yes, this is deliberately a long way away from normal numbers.
*/

.CONST $MESSAGE_IMMEDIATE_PANIC  0xFFC0;


/*
  The following messages are used internally by the firmware and DSP
  libraries to allow passing longer messages. They will never be seen
  by application code in the VM or the DSP.

  DSP <-> FW

  MSG_PART_BASE..MSG_PART_BASE+3 have a 4 word payload.

  If bit 1 is set then this is the initial packet and starts with the
  id and length of the long message

  If bit 2 is set then this is the final packet of the long message
*/

.CONST $MESSAGE_PART_BASE                    0xFFF0;

#endif

