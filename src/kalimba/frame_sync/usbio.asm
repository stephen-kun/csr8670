// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#if !defined(FRAME_SYNC_DEBUG)
// Define FRAME_SYNC_DEBUG here to allow USBIO debug (this is also enabled by
// frame sync debug build variant)
//#define FRAME_SYNC_DEBUG
#endif

// Define USB_IN_RETRYS to allow more than one USB input packet per timer interrupt
#define USB_IN_RETRYS

// *****************************************************************************
// NAME:
//    USB IO Library
//
// DESCRIPTION:
//    This library provides an API for dealing with transferring data between a
//    USB MMU Port and cbuffers
//
//    For reading from a USB MMU port a specific protocal is required to extract
//    the data.  Due to this protocal interpretation the read operation does
//    not fit into the CBOPs operator architecture.  Also, read operations
//    should be performed based on USB audio packet size which is always 1 msec
//    of audio regardless of sample rate.
//
//    Based on the above constraints the USB copy in functions should be called
//    directly, within a 1 msec timer task.
//
//    For stereo USB audio TBD
//
//    For Mono USB audio TBD
//
//
//    For writing to a USB MMU port the CBOPs operator architecture is
//    supported.  For Mono USB audio the standard operator set may be used.
//    However, to manage stereo USB audio a function is provided in this
//    library.
//
//    Both the API for reading USB data and the operators for writing USB data
//    are designed to operate with the frame sync architecture.
//
// *****************************************************************************
#include "stack.h"
#include "usbio.h"
#include "architecture.h"


// *****************************************************************************
// MODULE:
//    $frame_sync.usb_in_stereo_audio_copy
//
// DESCRIPTION:
//    Copy available USB audio data from a read port to two cbuffers.
//
// INPUTS:
//    - r8 = pointer to operator structure:
//       - USB_IN_STEREO_COPY_SOURCE_FIELD            [In] USB input port (port ID)
//       - USB_IN_STEREO_COPY_LEFT_SINK_FIELD         [In] Left audio output cbuffer (address of cbuffer structure)
//       - USB_IN_STEREO_COPY_RIGHT_SINK_FIELD        [In] Right audio output cbuffer (address of cbuffer structure)
//       - USB_IN_STEREO_COPY_PACKET_LENGTH_FIELD     [In] Length of "large" USB packet in bytes (e.g. 192)
//       - USB_IN_STEREO_COPY_SHIFT_AMOUNT_FIELD      [In] Gain shift applied to the samples on output
//       - USB_IN_STEREO_COPY_LAST_HEADER_FIELD       Previous sync byte value received (0..0x7f)
//       - USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD    [In] Packet sequence period in packets (e.g. 10 gives: 9 small, 1 large)
//       - USB_IN_STEREO_STATE_FIELD                  USB input state
//       - USB_IN_STEREO_PACKET_COUNTER_FIELD         Packet counter (0..$frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD - 1)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r6, r7, I0, I4, I5, L0 = 0, L5 = 0, r10, DoLoop
//
// NOTES:
//    When enumerating on USB as a sound device we get a single byte stream of
//    data.  This consists of a byte of header followed by a number of
//    16bit samples.  If stereo mode is selected then samples are alternately
//    left and then right.  USB 16bit samples are LSbyte first which is the MMU
//    port's default mode.
//
//    If the input USB port stalls (i.e. there is no data available) then
//    no special action is taken.
//
// *****************************************************************************
.MODULE $M.frame_sync.usb_in_stereo_audio_copy;

   .CODESEGMENT FRAME_SYNC_USB_IN_STEREO_AUDIO_COPY_PM;
   .DATASEGMENT DM;

   // Routines to call for given state of USB input packet handler
   .VAR usb_in_state_fn[] =
      idle,
      syncing_a,
      syncing_b,
      synced;

// Entry point
$frame_sync.usb_in_stereo_audio_copy:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(USB_IN_RETRYS)
   // Indicate this is not a retry
   M[r8 + $frame_sync.USB_IN_STEREO_COPY_RETRY_FIELD] = 0;

   // Jump here to retry for more USB packets
   $frame_sync.usb_in_stereo_audio_copy_retry:
#endif

   // USB input port
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD];

   // Get the DSP port number
   r6 = r0 AND $cbuffer.PORT_NUMBER_MASK;
   r4 = r6;
#ifdef NON_CONTIGUOUS_PORTS
   r2 = ($READ_CONFIG_GAP - 1);
   r3 = ($READ_DATA_GAP - 1);
   Null = ($cbuffer.TOTAL_CONTINUOUS_PORTS - 1) - r6;
   if POS jump lower_port;
      r4 = r6 + r2;  // Config offset
      r6 = r6 + r3;  // Data offset
   lower_port:
#endif

   // USB port read address & size
   I4 = r6 + $READ_PORT0_DATA;

   // Jump to the routine based on the state
   r1 = M[r8 + $frame_sync.USB_IN_STEREO_STATE_FIELD];
   r0 = M[usb_in_state_fn + r1];
   jump r0;

// Handle idle state
//  Detect the start of a packet (gap then data)
idle:
   // Reset the packet counter
   M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNTER_FIELD] = 0;

   // Force the modulo count to be 1 if defaulted to zero (for backward compatibility)
   r0 = 1;
   r1 = M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD];
   if NZ r0 = r1;
   M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD] = r0;

   // Switch input to 8bit read mode
   M[r4 + $READ_PORT0_CONFIG] = 0;

   // Empty the USB input port
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;
   r10 = r1;

   do empty_loop;
      r0 = M[I4, 0];
   empty_loop:

   // Force an MMU buffer set
   null = M[$PORT_BUFFER_SET];

   // Get the amount of data in the USB input port
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;

   // If data is present (i.e. more data is received during the port empty), assume this is part way through a packet
   // and so stay in idle state and keep searching for start of packet
   null = r1;
   if NZ jump exit;

   // If no data, assume that the next data received is the start of a packet
   r0 = $frame_sync.SYNCING_A_STATE;
   M[r8 + $frame_sync.USB_IN_STEREO_STATE_FIELD] = r0;

   jump exit;

// Handle syncing_a, syncing_b states (looks to see where the next sync byte is located)
syncing_a:
syncing_b:

   // Get the amount of data (r1 in bytes) in the USB input port
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;

   // Check that there is enough data for at least a sync byte and a "large" packet of data
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_PACKET_LENGTH_FIELD];
   r10 = r0 - 4;                                      // Keep "small" packet size in bytes for skipping data later
   r0 = r0 + 1;                                       // Add 1 sync byte
   null = r1 - r0;                                    // r1=amount in bytes
   if NEG jump exit;                                  // Not enough data yet, so exit and keep in state

   // Get the previous sync byte
   r1 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_LAST_HEADER_FIELD];

   // Calculate the expected sync byte
   r1 = r1 + 1;
   r1 = r1 AND $frame_sync.SYNC_MASK;

   // Get the sync byte (assuming this is a "small" packet)
   r0 = M[I4, 0];

   // Can only determine the packet size after the second sync byte
   r2 = M[r8 + $frame_sync.USB_IN_STEREO_STATE_FIELD];
   r3 = $frame_sync.SYNCING_B_STATE;                  // Force into SYNCING_B_STATE
   M[r8 + $frame_sync.USB_IN_STEREO_STATE_FIELD] = r3;
   null = r2 - $frame_sync.SYNCING_A_STATE;           // Is this the first sync byte?
   if Z jump skip_and_update;                         // Yes - skip and find next

   // Next sync byte in sequence?
   null = r1 - r0;

   // Was it a "small" packet? - if yes: jump (Stay in state: SYNCING_B_STATE)
   if Z jump skip_and_update;

   // Assume this is a "large" packet so check for sync byte 1 sample later
   r0 = M[I4, 0];                                     // Skip 3 bytes
   r0 = M[I4, 0];                                     //
   r0 = M[I4, 0];                                     //

   // Get the sync byte (assuming this is a "large" packet)
   r0 = M[I4, 0];

   // Next sync byte in sequence?
   null = r1 - r0;

   // Was it a "large" packet? - if yes: jump
   if Z jump large_packet;

      // Not a "small" or "large" packet so restart the search for the sync byte
      r0 = $frame_sync.IDLE_STATE;
      M[r8 + $frame_sync.USB_IN_STEREO_STATE_FIELD] = r0;

      jump exit;

   large_packet:

   // Set the packet counter to identify positions of "large" packets
   r1 = M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD];
   r1 = r1 - 2;                                       // Check if all packets are "large"
   if POS jump skip_all_large;

      r1 = 0;                                         // Set the packet count for the first packet in the "synced" state to "large"
      r10 = r10 + 4;                                  // Skip an extra stereo sample (4 bytes)

   skip_all_large:

   // Set the packet count for the first packet in the "synced" state
   M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNTER_FIELD] = r1;

   r1 = $frame_sync.SYNCED_STATE;                     // Change state (found "large" packet so synced)
   M[r8 + $frame_sync.USB_IN_STEREO_STATE_FIELD] = r1;

   skip_and_update:

   // Store the sync byte just read
   M[r8 + $frame_sync.USB_IN_STEREO_COPY_LAST_HEADER_FIELD] = r0;

   // Assume the next is a "small" packet - skip N samples: N * 4 bytes
   do skip_loop;

      r0 = M[I4, 0];                                  // Skip a byte

   skip_loop:

   // Update the USB port access regs
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD];
   r1 = I4;
   call $cbuffer.set_read_address;

   jump exit;                                         // Exit

// Handle synced state
synced:

   // Find the amount of space in the left sink cbuffer
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_LEFT_SINK_FIELD];
   call $cbuffer.calc_amount_space;
   r3 = r0;

   // Find the amount of space in the right sink cbuffer
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_RIGHT_SINK_FIELD];
   call $cbuffer.calc_amount_space;

   // Calculate max number of locations that we could write to the sinks
   null = r3 - r0;
   if POS r3 = r0;

   // Must be at least a "large" packet worth of space in the sink cbuffers
   r7 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_PACKET_LENGTH_FIELD];
   r7 = r7 ASHIFT -2;                                 // "large" packet size in samples
   NULL = r3 - r7;                                    // Enough space?

#if defined(FRAME_SYNC_DEBUG)
   if POS jump skip_usbio_full_count;

      .VAR $debug_usbio_in_stereo_full_count;

      // Count the number of times the sink buffers are too full for a transfer (for debug)
      r0 = M[$debug_usbio_in_stereo_full_count];
      r0 = r0 + 1;
      M[$debug_usbio_in_stereo_full_count] = r0;
      jump exit;                                      // No - exit

   skip_usbio_full_count:
#else
   if NEG jump exit;                                  // No - exit
#endif

   // Force an MMU buffer set
   null = M[$PORT_BUFFER_SET];

   // Get the amount of data (r1 in bytes) in the USB input port
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;

   r10 = -4;                                          // Assume it's a "small" packet therefore need 1 less sample (r10=-4)
   r3 = M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNTER_FIELD];  // Get the packet counter (zero if a "large" packet is expected)
   if Z r10 = r10 - r10;                              // If it's a "large" packet then use the packet length (r10=0)

   // Check that there is enough data for at least a sync byte and a "small" or "large" packet (as appropriate) of data
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_PACKET_LENGTH_FIELD];  //
   r0 = r0 + r10;                                     // Get the expected number of bytes in the packet (could be "small" or "large")
   r10 = r0 LSHIFT -2;                                // Convert to samples (for copy)
   r0 = r0 + 1;                                       // Add 1 sync byte
   null = r1 - r0;                                    // r1=amount in bytes
   if NEG jump exit;                                  // If not enough input exit

#if defined(FRAME_SYNC_DEBUG)
#if defined(USB_IN_RETRYS)
      .VAR $debug_usbio_in_stereo_successful_retry_count;

      // Is this a retry? - if yes then count
      null = M[r8 + $frame_sync.USB_IN_STEREO_COPY_RETRY_FIELD];
      if Z jump no_retry;

         // Count the number of successful retrys (for debug)
         r0 = M[$debug_usbio_in_stereo_successful_retry_count];
         r0 = r0 + 1;
         M[$debug_usbio_in_stereo_successful_retry_count] = r0;

      no_retry:
#endif
#endif

   // Decrement (modulo n) the packet counter and store
   r1 = M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD];
   r1 = r1 - 1;
   r0 = r3 - 1;
   if NEG r0 = r1;
   M[r8 + $frame_sync.USB_IN_STEREO_PACKET_COUNTER_FIELD] = r0;

   // Read sync and copy data
   call usb_in_stereo_copy_helper;

#if defined(USB_IN_RETRYS)
   // Attempt a retry (if more USB input packets are available in the input port
   // and sufficient output buffer space exists this will fetch/process another packet)

   // Indicate this is a retry (after already transferring a packet on this timer interrupt)
   r0 = 1;
   M[r8 + $frame_sync.USB_IN_STEREO_COPY_RETRY_FIELD] = r0;
   jump $frame_sync.usb_in_stereo_audio_copy_retry;
#endif

   // Exit and remain in state
exit:

   // Linear buffer addressing
   L0 = 0;
   L5 = 0;

   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $frame_sync.usb_in_stereo_copy_helper
//
// DESCRIPTION:
//    Copy helper. Reads a sync byte then copies samples from the USB
//    input port to the PCM output cbuffer/port.
//
// INPUTS:
//    - r4 = Input port config offset (i.e. rel to $READ_PORT0_CONFIG)
//    - r6 = Input port data offset (i.e. rel to $READ_PORT0_DATA)
//    - r8 = pointer to frame_sync usb in structure
//    - r10 = number of stereo samples to copy
//    - I4 = USB port read address (i.e. r6 + $READ_PORT0_DATA)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r6, r7, I0, I4, I5, L0, L5, r10, DoLoop
//
// NOTES:
//
// *****************************************************************************

// Entry point
usb_in_stereo_copy_helper:

   // push rLink onto stack
   $push_rLink_macro;

   // Get the previous sync byte
   r1 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_LAST_HEADER_FIELD];

   // Calculate the expected sync byte
   r1 = r1 + 1;
   r1 = r1 AND $frame_sync.SYNC_MASK;

   // Switch input to 8bit read mode
   M[r4 + $READ_PORT0_CONFIG] = 0;

   // Read a byte (assumed to be the current sync byte)
   r0 = M[I4, 0];

   // Store the sync byte just read
   M[r8 + $frame_sync.USB_IN_STEREO_COPY_LAST_HEADER_FIELD] = r0;

   // Next sync byte in sequence?
   null = r1 - r0;

   // If matched then still in sync
   if Z jump sync_match;

#if defined(FRAME_SYNC_DEBUG)
      .VAR $debug_usbio_in_stereo_resync_count;
      .VAR $debug_usbio_in_stereo_expected_sync;
      .VAR $debug_usbio_in_stereo_actual_sync;

      M[$debug_usbio_in_stereo_expected_sync] = r1;
      M[$debug_usbio_in_stereo_actual_sync] = r0;

      // Count the number of re-syncs (for debug)
      r0 = M[$debug_usbio_in_stereo_resync_count];
      r0 = r0 + 1;
      M[$debug_usbio_in_stereo_resync_count] = r0;
#endif

      // Not synced (or sync lost) so restart search for the sync byte
      r0 = $frame_sync.IDLE_STATE;
      M[r8 + $frame_sync.USB_IN_STEREO_STATE_FIELD] = r0;

      jump lexit;

   sync_match:
   copy_data:

   // Switch input to 16bit read mode for copy
   r0 = $BITMODE_16BIT_ENUM;
   M[r4 + $READ_PORT0_CONFIG] = r0;

   // Copy N stereo samples (N*2*2 bytes)

   // Set up index and length registers for the left channel
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_LEFT_SINK_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
   push r2;
   pop  B0;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   I0 = r0;
   L0 = r1;

   // Set up index and length registers for the right channel
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_RIGHT_SINK_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
   push r2;
   pop  B5;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   I5 = r0;
   L5 = r1;

   // Gain shift to apply to samples
   r3 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_SHIFT_AMOUNT_FIELD];

   // Loop to copy data from the USB input port to the L & R output/port cbuffer
   do lp_stereo_loop;

      // Read and write the left channel sample
      r0 = M[I4,0];
      r0 = r0 ASHIFT r3;

      // Read and write the right channel sample
      r1 = M[I4,0];
      r1 = r1 ASHIFT r3;

      // Write Outputs
      M[I0,1] = r0, M[I5,1] = r1;

   lp_stereo_loop:

   // Update the USB port access regs (next byte read will be the sync byte after a "large" packet)
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD];
   r1 = I4;
   call $cbuffer.set_read_address;

   // Update buffer write address for the left channel
   // and amount of data for frame sync
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_LEFT_SINK_FIELD];
   r1 = I0;
   call $cbuffer.set_write_address;

#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif

   // Update buffer write address for the right channel
   r0 = M[r8 + $frame_sync.USB_IN_STEREO_COPY_RIGHT_SINK_FIELD];
   r1 = I5;
   call $cbuffer.set_write_address;

#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B5;
#endif

lexit:

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $frame_sync.usb_in_mono_audio_copy
//
// DESCRIPTION:
//    Copy available USB audio data from a read port to two cbuffers.
//
// INPUTS:
//    - r8 = pointer to operator structure:
//       - USB_IN_MONO_COPY_SOURCE_FIELD            [In] USB input port (port ID)
//       - USB_IN_MONO_COPY_SINK_FIELD              [In] Audio output cbuffer (address of cbuffer structure)
//       - USB_IN_MONO_COPY_PACKET_LENGTH_FIELD     [In] Length of "large" USB packet in bytes (e.g. 96)
//       - USB_IN_MONO_COPY_SHIFT_AMOUNT_FIELD      [In] Gain shift applied to the samples on output
//       - USB_IN_MONO_COPY_LAST_HEADER_FIELD       Previous sync byte value received (0..0x7f)
//       - USB_IN_MONO_PACKET_COUNT_MODULO_FIELD    [In] Packet sequence period in packets (e.g. 10 gives: 9 small, 1 large)
//       - USB_IN_MONO_STATE_FIELD                  USB input state
//       - USB_IN_MONO_PACKET_COUNTER_FIELD         Packet counter (0..$frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD - 1)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r6, r7, I0, I4, L0 = 0, r10, DoLoop
//
// NOTES:
//    When enumerating on USB as a sound device we get a single byte stream of
//    data.  This consists of a byte of header followed by a number of
//    16bit samples. USB 16bit samples are LSbyte first which is the MMU
//    port's default mode.
//
//    If the input USB port stalls (i.e. there is no data available) then
//    no special action is taken.
//
// *****************************************************************************
.MODULE $M.frame_sync.usb_in_mono_audio_copy;

   .CODESEGMENT FRAME_SYNC_USB_IN_MONO_AUDIO_COPY_PM;
   .DATASEGMENT DM;

   // Routines to call for given state of USB input packet handler
   .VAR usb_in_state_fn[] =
      idle,
      syncing_a,
      syncing_b,
      synced;

// Entry point
$frame_sync.usb_in_mono_audio_copy:

   // push rLink onto stack
   $push_rLink_macro;

#if defined(USB_IN_RETRYS)
   // Indicate this is not a retry
   M[r8 + $frame_sync.USB_IN_MONO_COPY_RETRY_FIELD] = 0;

   // Jump here to retry for more USB packets
   $frame_sync.usb_in_mono_audio_copy_retry:
#endif

   // USB input port
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD];

   // Get the DSP port number
   r6 = r0 AND $cbuffer.PORT_NUMBER_MASK;
   r4 = r6;
#ifdef NON_CONTIGUOUS_PORTS
   r2 = ($READ_CONFIG_GAP - 1);
   r3 = ($READ_DATA_GAP - 1);
   Null = ($cbuffer.TOTAL_CONTINUOUS_PORTS - 1) - r6;
   if POS jump lower_port;
      r4 = r6 + r2;  // Config offset
      r6 = r6 + r3;  // Data offset
   lower_port:
#endif

   // USB port read address & size
   I4 = r6 + $READ_PORT0_DATA;

   // Jump to the routine based on the state
   r1 = M[r8 + $frame_sync.USB_IN_MONO_STATE_FIELD];
   r0 = M[usb_in_state_fn + r1];
   jump r0;

// Handle idle state
//  Detect the start of a packet (gap then data)
idle:
   // Reset the packet counter
   M[r8 + $frame_sync.USB_IN_MONO_PACKET_COUNTER_FIELD] = 0;

   // Force the modulo count to be 1 if defaulted to zero (for backward compatibility)
   r0 = 1;
   r1 = M[r8 + $frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD];
   if NZ r0 = r1;
   M[r8 + $frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD] = r0;

   // Switch input to 8bit read mode
   M[r4 + $READ_PORT0_CONFIG] = 0;

   // Empty the USB input port
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;
   r10 = r1;

   do empty_loop;
      r0 = M[I4, 0];
   empty_loop:

   // Force an MMU buffer set
   null = M[$PORT_BUFFER_SET];

   // Get the amount of data in the USB input port
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;

   // If data is present (i.e. more data is received during the port empty), assume this is part way through a packet
   // and so stay in idle state and keep searching for start of packet
   null = r1;
   if NZ jump exit;

   // If no data, assume that the next data received is the start of a packet
   r0 = $frame_sync.SYNCING_A_STATE;
   M[r8 + $frame_sync.USB_IN_MONO_STATE_FIELD] = r0;

   jump exit;

// Handle syncing_a, syncing_b states (looks to see where the next sync byte is located)
syncing_a:
syncing_b:

   // Get the amount of data (r1 in bytes) in the USB input port
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;

   // Check that there is enough data for at least a sync byte and a "large" packet of data
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_PACKET_LENGTH_FIELD];
   r10 = r0 - 2;                                      // Keep "small" packet size in bytes for skipping data later
   r0 = r0 + 1;                                       // Add 1 sync byte
   null = r1 - r0;                                    // r1=amount in bytes
   if NEG jump exit;                                  // Not enough data yet, so exit and keep in state

   // Get the previous sync byte
   r1 = M[r8 + $frame_sync.USB_IN_MONO_COPY_LAST_HEADER_FIELD];

   // Calculate the expected sync byte
   r1 = r1 + 1;
   r1 = r1 AND $frame_sync.SYNC_MASK;

   // Get the sync byte (assuming this is a "small" packet)
   r0 = M[I4, 0];

   // Can only determine the packet size after the second sync byte
   r2 = M[r8 + $frame_sync.USB_IN_MONO_STATE_FIELD];
   r3 = $frame_sync.SYNCING_B_STATE;                  // Force into SYNCING_B_STATE
   M[r8 + $frame_sync.USB_IN_MONO_STATE_FIELD] = r3;
   null = r2 - $frame_sync.SYNCING_A_STATE;           // Is this the first sync byte?
   if Z jump skip_and_update;                         // Yes - skip and find next

   // Next sync byte in sequence?
   null = r1 - r0;

   // Was it a "small" packet? - if yes: jump (Stay in state: SYNCING_B_STATE)
   if Z jump skip_and_update;

   // Assume this is a "large" packet so check for sync byte 1 sample later
   r0 = M[I4, 0];                                     // Skip 1 bytes

   // Get the sync byte (assuming this is a "large" packet)
   r0 = M[I4, 0];

   // Next sync byte in sequence?
   null = r1 - r0;

   // Was it a "large" packet? - if yes: jump
   if Z jump large_packet;

      // Not a "small" or "large" packet so restart the search for the sync byte
      r0 = $frame_sync.IDLE_STATE;
      M[r8 + $frame_sync.USB_IN_MONO_STATE_FIELD] = r0;

      jump exit;

   large_packet:

   // Set the packet counter to identify positions of "large" packets
   r1 = M[r8 + $frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD];
   r1 = r1 - 2;                                       // Check if all packets are "large"
   if POS jump skip_all_large;

      r1 = 0;                                         // Set the packet count for the first packet in the "synced" state to "large"
      r10 = r10 + 2;                                  // Skip an extra mono sample (2 bytes)

   skip_all_large:

   // Set the packet count for the first packet in the "synced" state
   M[r8 + $frame_sync.USB_IN_MONO_PACKET_COUNTER_FIELD] = r1;

   r1 = $frame_sync.SYNCED_STATE;                     // Change state (found "large" packet so synced)
   M[r8 + $frame_sync.USB_IN_MONO_STATE_FIELD] = r1;

   skip_and_update:

   // Store the sync byte just read
   M[r8 + $frame_sync.USB_IN_MONO_COPY_LAST_HEADER_FIELD] = r0;

   // Assume the next is a "small" packet - skip N samples: N * 2 bytes
   do skip_loop;

      r0 = M[I4, 0];                                  // Skip a byte

   skip_loop:

   // Update the USB port access regs
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD];
   r1 = I4;
   call $cbuffer.set_read_address;

   jump exit;                                         // Exit

// Handle synced state
synced:

   // Find the amount of space in the sink cbuffer
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SINK_FIELD];
   call $cbuffer.calc_amount_space;
   r3 = r0;

   // Must be at least a "large" packet worth of space in the sink cbuffers
   r7 = M[r8 + $frame_sync.USB_IN_MONO_COPY_PACKET_LENGTH_FIELD];
   r7 = r7 ASHIFT -1;                                 // "large" packet size in samples
   NULL = r3 - r7;                                    // Enough space?

#if defined(FRAME_SYNC_DEBUG)
   if POS jump skip_usbio_full_count;

      .VAR $debug_usbio_in_mono_full_count;

      // Count the number of times the sink buffers are too full for a transfer (for debug)
      r0 = M[$debug_usbio_in_mono_full_count];
      r0 = r0 + 1;
      M[$debug_usbio_in_mono_full_count] = r0;
      jump exit;                                      // No - exit

   skip_usbio_full_count:
#else
   if NEG jump exit;                                  // No - exit
#endif

   // Force an MMU buffer set
   null = M[$PORT_BUFFER_SET];

   // Get the amount of data (r1 in bytes) in the USB input port
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;

   r10 = -2;                                          // Assume it's a "small" packet therefore need 1 less sample (r10=-2)
   r3 = M[r8 + $frame_sync.USB_IN_MONO_PACKET_COUNTER_FIELD];  // Get the packet counter (zero if a "large" packet is expected)
   if Z r10 = r10 - r10;                              // If it's a "large" packet then use the packet length (r10=0)

   // Check that there is enough data for at least a sync byte and a "small" or "large" packet (as appropriate) of data
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_PACKET_LENGTH_FIELD];  //
   r0 = r0 + r10;                                     // Get the expected number of bytes in the packet (could be "small" or "large")
   r10 = r0 LSHIFT -1;                                // Convert to samples (for copy)
   r0 = r0 + 1;                                       // Add 1 sync byte
   null = r1 - r0;                                    // r1=amount in bytes
   if NEG jump exit;                                  // If not enough input exit

#if defined(FRAME_SYNC_DEBUG)
#if defined(USB_IN_RETRYS)
      .VAR $debug_usbio_in_mono_successful_retry_count;

      // Is this a retry? - if yes then count
      null = M[r8 + $frame_sync.USB_IN_MONO_COPY_RETRY_FIELD];
      if Z jump no_retry;

         // Count the number of successful retrys (for debug)
         r0 = M[$debug_usbio_in_mono_successful_retry_count];
         r0 = r0 + 1;
         M[$debug_usbio_in_mono_successful_retry_count] = r0;

      no_retry:
#endif
#endif

   // Decrement (modulo n) the packet counter and store
   r1 = M[r8 + $frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD];
   r1 = r1 - 1;
   r0 = r3 - 1;
   if NEG r0 = r1;
   M[r8 + $frame_sync.USB_IN_MONO_PACKET_COUNTER_FIELD] = r0;

   // Read sync and copy data
   call usb_in_mono_copy_helper;

#if defined(USB_IN_RETRYS)
   // Attempt a retry (if more USB input packets are available in the input port
   // and sufficient output buffer space exists this will fetch/process another packet)

   // Indicate this is a retry (after already transferring a packet on this timer interrupt)
   r0 = 1;
   M[r8 + $frame_sync.USB_IN_MONO_COPY_RETRY_FIELD] = r0;
   jump $frame_sync.usb_in_mono_audio_copy_retry;
#endif

   // Exit and remain in state
exit:

   // Linear buffer addressing
   L0 = 0;

   jump $pop_rLink_and_rts;

// *****************************************************************************
// MODULE:
//    $frame_sync.usb_in_mono_copy_helper
//
// DESCRIPTION:
//    Copy helper. Reads a sync byte then copies samples from the USB
//    input port to the PCM output cbuffer/port.
//
// INPUTS:
//    - r4 = Input port config offset (i.e. rel to $READ_PORT0_CONFIG)
//    - r6 = Input port data offset (i.e. rel to $READ_PORT0_DATA)
//    - r8 = pointer to frame_sync usb in structure
//    - r10 = number of mono samples to copy
//    - I4 = USB port read address (i.e. r6 + $READ_PORT0_DATA)
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r6, r7, I0, I4, L0, r10, DoLoop
//
// NOTES:
//
// *****************************************************************************

// Entry point
usb_in_mono_copy_helper:

   // push rLink onto stack
   $push_rLink_macro;

   // Get the previous sync byte
   r1 = M[r8 + $frame_sync.USB_IN_MONO_COPY_LAST_HEADER_FIELD];

   // Calculate the expected sync byte
   r1 = r1 + 1;
   r1 = r1 AND $frame_sync.SYNC_MASK;

   // Switch input to 8bit read mode
   M[r4 + $READ_PORT0_CONFIG] = 0;

   // Read a byte (assumed to be the current sync byte)
   r0 = M[I4, 0];

   // Store the sync byte just read
   M[r8 + $frame_sync.USB_IN_MONO_COPY_LAST_HEADER_FIELD] = r0;

   // Next sync byte in sequence?
   null = r1 - r0;

   // If matched then still in sync
   if Z jump sync_match;

#if defined(FRAME_SYNC_DEBUG)
      .VAR $debug_usbio_in_mono_resync_count;
      .VAR $debug_usbio_in_mono_expected_sync;
      .VAR $debug_usbio_in_mono_actual_sync;

      M[$debug_usbio_in_mono_expected_sync] = r1;
      M[$debug_usbio_in_mono_actual_sync] = r0;

      // Count the number of re-syncs (for debug)
      r0 = M[$debug_usbio_in_mono_resync_count];
      r0 = r0 + 1;
      M[$debug_usbio_in_mono_resync_count] = r0;
#endif

      // Not synced (or sync lost) so restart search for the sync byte
      r0 = $frame_sync.IDLE_STATE;
      M[r8 + $frame_sync.USB_IN_MONO_STATE_FIELD] = r0;

      jump lexit;

   sync_match:
   copy_data:

   // Switch input to 16bit read mode for copy
   r0 = $BITMODE_16BIT_ENUM;
   M[r4 + $READ_PORT0_CONFIG] = r0;

   // Copy N mono samples (N*2 bytes)

   // Set up index and length registers for the output
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SINK_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
   push r2;
   pop  B0;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   I0 = r0;
   L0 = r1;

   // Gain shift to apply to samples
   r3 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SHIFT_AMOUNT_FIELD];

   // Loop to copy data from the USB input cbuffer/port to the output/port cbuffer
   do lp_mono_loop;

      // Read the input sample
      r0 = M[I4,0];
      r0 = r0 ASHIFT r3;

      // Write the output sample
      M[I0,1] = r0;

   lp_mono_loop:

   // Update the USB port access regs (next byte read will be the sync byte after a "large" packet)
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD];
   r1 = I4;
   call $cbuffer.set_read_address;

   // Update buffer write address for the output
   r0 = M[r8 + $frame_sync.USB_IN_MONO_COPY_SINK_FIELD];
   r1 = I0;
   call $cbuffer.set_write_address;

#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif

lexit:

   jump $pop_rLink_and_rts;

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $frame_sync.usb_out_stereo_copy
//
// DESCRIPTION:
//    Copy available usb audio data from 2 cbuffers
//
// INPUTS:
//   - r8 = pointer to structure:
//
// TRASHED:
//   - r0, r1, r2, r3, r4, r5, I0, I4, M0, doLoop
//
// The audio data is interlaced left/right into the USB MMU port
//
//
//
// NOTES:
//
//  This driver attempts to maintain one packet (1ms worth) of data in the port.
//
//  Because of jitter, it should be run at a sub-1ms interval (ie 750us).
//
//  If it must be run at a >=1ms interval, then TRANSFER_PER_PERIOD_FEILD
//     should be increased to ensure that the port never runs out of data.
//
//  NOTE: No latency control implemented.
//
//
//
// *****************************************************************************
.MODULE $M.frame_sync.usb_out_stereo_copy;
   .CODESEGMENT FRAME_SYNC_USB_OUT_STEREO_COPY_PM;
   .DATASEGMENT DM;

   .VAR last_limit = -1;
   .VAR ZeroBuf = 0x0;
   .VAR delay_buffer_read = 1;

$frame_sync.usb_out_stereo_copy:

   $push_rLink_macro;

   // assume the port is stalled
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_STALL_CNT_FIELD];
   r3 = r0 + 1;
   if Z r3 = r0;
   M[r8 + $frame_sync.USB_OUT_STEREO_STALL_CNT_FIELD] =  r3;

   // get the DSP port number
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_SINK_FIELD];
   r4 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
   r4 = r4 - $cbuffer.NUM_PORTS;
   r5 = r4;
#ifdef NON_CONTIGUOUS_PORTS
   r1 = ($WRITE_CONFIG_GAP - 1);
   r0 = ($WRITE_DATA_GAP - 1);
   Null = ($cbuffer.TOTAL_CONTINUOUS_PORTS - 1) - r4;
   if POS jump lower_port;
      r5 = r4 + r1;  // Config offset
      r4 = r4 + r0;  // Data offset
   lower_port:
#endif

   r1 = M[r4 + $cbuffer.write_port_limit_addr];

   // set port configuration
   r0 = ($SATURATE_MASK + $BITMODE_16BIT_ENUM);
   M[r5 + $WRITE_PORT0_CONFIG] = r0;


// stall check..
// *****************************************
   r1 = M[r1]; // get limit
   r0 = M[last_limit];
   M[last_limit] = r1;
   Null = r1 - r0;
   if Z jump stall_detected;
   M[r8 + $frame_sync.USB_OUT_STEREO_STALL_CNT_FIELD] = 0; // not stalled,
   jump not_stalled;
stall_detected:
   Null = r3 - $USB_STALL_CNT_THRESH;
   if NEG jump not_stalled;             // not past threshold. proceed
   if Z jump purgeport;                 // first time stalled. purge the port once


   // stalled > threshold counts. purge buffers
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_LEFT_SOURCE_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   r1=r0;
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_LEFT_SOURCE_FIELD];
   call $cbuffer.set_read_address;

   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_RIGHT_SOURCE_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   r1=r0;
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_RIGHT_SOURCE_FIELD];
   call $cbuffer.set_read_address;

   jump $pop_rLink_and_rts;

not_stalled:
// transfer data... try to maintain one packet in the port
// *****************************************

   M0 = 0;        // assume we wont read from buffers
   I0 = &ZeroBuf;
   I4 = &ZeroBuf;

   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_SINK_FIELD];
   call $cbuffer.calc_amount_space;
   r2 = r2 LSHIFT -1; // buffer size in words
   r0 = r2 - r0;
   r0 = r0 - 1;
   r0 = r0 LSHIFT - 1; // r0= amount of words in port/2

   r10 = M[r8 + $frame_sync.USB_OUT_STEREO_TRANSFER_PER_PERIOD_FIELD];
   Null = r0 - r10;
   if POS jump $pop_rLink_and_rts; // theres enough data in the port. exit.

   // get available buffer data. exit if not enough
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_LEFT_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;
   Null = r0 - r10;
   if NEG jump not_enough_buffer_data;
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_RIGHT_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;
   Null = r0 - r10;
   if NEG jump not_enough_buffer_data;

   // if we're here, there is enough data in the buffer

   Null = M[delay_buffer_read];       // one-time delay (after stall) to allow
   if Z jump setup_transfer;          // a period of padding in the buffer
   M[delay_buffer_read] = 0;
   jump not_enough_buffer_data;

setup_transfer:
   // r10 is amt_to_xfer. setup for transfer
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_LEFT_SOURCE_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop  B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I0 = r0;
   L0 = r1;
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_RIGHT_SOURCE_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop  B4;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I4 = r0;
   L4 = r1;
   M0 = 1;

not_enough_buffer_data:
   // read the shift amount to use from the parameter area
   r3 = M[r8 + $frame_sync.USB_OUT_STEREO_SHIFT_AMOUNT_FIELD];

   // transfer data to port
   do loop;
      r1 = M[I0,M0], r0 = M[I4,M0];
      r1 = r1 ASHIFT r3;
      M[$WRITE_PORT0_DATA+r4] = r1;
      r0 = r0 ASHIFT r3;
      M[$WRITE_PORT0_DATA+r4] = r0;
loop:
   // zero the length registers
   L0 = 0;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif
   L4 = 0;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B4;
#endif
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_SINK_FIELD];
   call $cbuffer.set_write_address;
   Null = M0;
   if Z jump $pop_rLink_and_rts; // did not read from buffers. exit

   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_LEFT_SOURCE_FIELD];
   r1 = I0;
   call $cbuffer.set_read_address;
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_RIGHT_SOURCE_FIELD];
   r1 = I4;
   call $cbuffer.set_read_address;

   jump $pop_rLink_and_rts;

purgeport:

// purge the port to remove stale data. Leave 1 packet of zeros
// *****************************************
   M[delay_buffer_read] = r8;  // signal delayed buffer read

   // purge the port
   Null = M[$PORT_BUFFER_SET];
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_SINK_FIELD];
   call $cbuffer.calc_amount_space;
   r10 = r0 + 1;  // read=write
   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_TRANSFER_PER_PERIOD_FIELD];
   r10 = r10 + r0; // add packet of zeros so port has some data when it wakes
   r10 = r10 + r0; // stereo

   r0 = 0;
   do flushport;
      M[$WRITE_PORT0_DATA+r4] = r0;
flushport:

   r0 = M[r8 + $frame_sync.USB_OUT_STEREO_SINK_FIELD];
   call $cbuffer.set_write_address;

   jump $pop_rLink_and_rts;
.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $frame_sync.usb_out_mono_copy
//
// DESCRIPTION:
//    Copy available usb audio data from 1 cbuffer
//
// INPUTS:
//   - r8 = pointer to structure:
//
// TRASHED:
//   - r0, r1, r2, r3, r4, r5, I0, M0, doLoop
//
//
// NOTES:
//
//  This driver attempts to maintain one packet (1ms worth) of data in the port.
//
//  Because of jitter, it should be run at a sub-1ms interval (ie 750us).
//
//  If it must be run at a >=1ms interval, then TRANSFER_PER_PERIOD_FEILD
//     should be increased to ensure that the port never runs out of data.
//
//  NOTE: No latency control implemented.
//
//
//
//
// *****************************************************************************
.MODULE $M.frame_sync.usb_out_mono_copy;
   .CODESEGMENT FRAME_SYNC_USB_OUT_MONO_COPY_PM;
   .DATASEGMENT DM;

   .VAR last_limit = -1;
   .VAR ZeroBuf = 0x0;
   .VAR delay_buffer_read = 1;

$frame_sync.usb_out_mono_copy:

   $push_rLink_macro;

   // assume the port is stalled
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_STALL_CNT_FIELD];
   r3 = r0 + 1;
   if Z r3 = r0;
   M[r8 + $frame_sync.USB_OUT_MONO_STALL_CNT_FIELD] =  r3;

   // get the DSP port number
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SINK_FIELD];
   r4 = r0 AND $cbuffer.TOTAL_PORT_NUMBER_MASK;
   r4 = r4 - $cbuffer.NUM_PORTS;
   r5 = r4;
#ifdef NON_CONTIGUOUS_PORTS
   r1 = ($WRITE_CONFIG_GAP - 1);
   r10 = ($WRITE_DATA_GAP - 1);
   Null = ($cbuffer.TOTAL_CONTINUOUS_PORTS - 1) - r4;
   if POS jump lower_port;
      r5 = r4 + r1;  // Config offset
      r4 = r4 + r10; // Data offset
   lower_port:
#endif
   r1 = M[r4 + $cbuffer.write_port_limit_addr];

   // set port configuration
   r0 = ($SATURATE_MASK + $BITMODE_16BIT_ENUM);
   M[r5 + $WRITE_PORT0_CONFIG] = r0;

// stall check..
// *****************************************
   r1 = M[r1]; // get limit
   r0 = M[last_limit];
   M[last_limit] = r1;
   Null = r1 - r0;
   if Z jump stall_detected;
   M[r8 + $frame_sync.USB_OUT_MONO_STALL_CNT_FIELD] = 0; // not stalled,
   jump not_stalled;
stall_detected:
   Null = r3 - $USB_STALL_CNT_THRESH;
   if NEG jump not_stalled;             // not past threshold. proceed
   if Z jump purgeport;                 // first time stalled. purge the port once


   // stalled > threshold counts. purge buffers
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SOURCE_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_write_address_and_size_and_start_address;
#else
   call $cbuffer.get_write_address_and_size;
#endif
   r1=r0;
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SOURCE_FIELD];
   call $cbuffer.set_read_address;
   jump $pop_rLink_and_rts;


not_stalled:
// transfer data... try to maintain one packet in the port
// *****************************************

   M0 = 0;        // assume we wont read from buffers
   I0 = &ZeroBuf;

   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SINK_FIELD];
   call $cbuffer.calc_amount_space;
   r2 = r2 LSHIFT -1; // buffer size in words
   r0 = r2 - r0;
   r0 = r0 - 1;      // r0= amount of words in port

   r10 = M[r8 + $frame_sync.USB_OUT_MONO_TRANSFER_PER_PERIOD_FIELD];
   Null = r0 - r10;
   if POS jump $pop_rLink_and_rts; // theres enough data in the port. exit.

   // get available buffer data. exit if not enough
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SOURCE_FIELD];
   call $cbuffer.calc_amount_data;
   Null = r0 - r10;
   if NEG jump not_enough_buffer_data;

   // if we're here, there is enough data in the buffer

   Null = M[delay_buffer_read];       // one-time delay (after stall) to allow
   if Z jump setup_transfer;          // a period of padding in the buffer
   M[delay_buffer_read] = 0;
   jump not_enough_buffer_data;

setup_transfer:
   // r10 is amt_to_xfer. setup for transfer
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SOURCE_FIELD];
#ifdef BASE_REGISTER_MODE
   call $cbuffer.get_read_address_and_size_and_start_address;
   push r2;
   pop  B0;
#else
   call $cbuffer.get_read_address_and_size;
#endif
   I0 = r0;
   L0 = r1;
   M0 = 1;
not_enough_buffer_data:
   // read the shift amount to use from the parameter area
   r3 = M[r8 + $frame_sync.USB_OUT_MONO_SHIFT_AMOUNT_FIELD];

   // transfer data to port
   do loop;
      r1 = M[I0,M0];
      r1 = r1 ASHIFT r3;
      M[$WRITE_PORT0_DATA+r4] = r1;
loop:
   // zero the length registers
   L0 = 0;
#ifdef BASE_REGISTER_MODE
   push Null;
   pop  B0;
#endif
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SINK_FIELD];
   call $cbuffer.set_write_address;
   Null = M0;
   if Z jump $pop_rLink_and_rts; // did not read from buffers. exit
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SOURCE_FIELD];
   r1 = I0;
   call $cbuffer.set_read_address;

   jump $pop_rLink_and_rts;


purgeport:

// purge the port to remove stale data. Leave 1 packet of zeros
// *****************************************
   M[delay_buffer_read] = r8;  // signal delayed buffer read

   // purge the port
   Null = M[$PORT_BUFFER_SET];
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SINK_FIELD];
   call $cbuffer.calc_amount_space;
   r10 = r0 + 1;  // read=write
   r0 = M[r8 + $frame_sync.USB_OUT_MONO_TRANSFER_PER_PERIOD_FIELD];
   r10 = r10 + r0; // add packet of zeros so port has some data when it wakes
   r0 = 0;

   do flushport;
      M[$WRITE_PORT0_DATA+r4] = r0;
flushport:

   r0 = M[r8 + $frame_sync.USB_OUT_MONO_SINK_FIELD];
   call $cbuffer.set_write_address;

   jump $pop_rLink_and_rts;
.ENDMODULE;
