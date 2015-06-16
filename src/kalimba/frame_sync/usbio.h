// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef FRAME_SYNC_USBIO_HEADER_INCLUDED
#define FRAME_SYNC_USBIO_HEADER_INCLUDED

// USB stall count threshold
.CONST    $USB_STALL_CNT_THRESH                                     7;

// Mask for sync byte counter
.CONST    $frame_sync.SYNC_MASK                                     0x7f;   // Sync byte is masked by this value

// USB Stereo Input Copy constants
.CONST    $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD               0;      // [In] USB input port
.CONST    $frame_sync.USB_IN_STEREO_COPY_LEFT_SINK_FIELD            1;      // [In] Left audio output cbuffer
.CONST    $frame_sync.USB_IN_STEREO_COPY_RIGHT_SINK_FIELD           2;      // [In] Right audio output cbuffer
.CONST    $frame_sync.USB_IN_STEREO_COPY_PACKET_LENGTH_FIELD        3;      // [In] Length of "large" USB packet in bytes (e.g. 192)
.CONST    $frame_sync.USB_IN_STEREO_COPY_SHIFT_AMOUNT_FIELD         4;      // [In] Gain shift applied to the samples on output
.CONST    $frame_sync.USB_IN_STEREO_COPY_LAST_HEADER_FIELD          5;      // Previous sync byte received (0..0x7f)
.CONST    $frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD       6;      // [In] Packet sequence period in packets (e.g. 10 gives: 9 small, 1 large)
.CONST    $frame_sync.USB_IN_STEREO_STATE_FIELD                     7;      // USB input state
.CONST    $frame_sync.USB_IN_STEREO_PACKET_COUNTER_FIELD            8;      // Packet counter (0..$frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD - 1)
.CONST    $frame_sync.USB_IN_STEREO_COPY_RETRY_FIELD                9;      // Retry flag indicates attempt to read more than 1 USB packet on a timer interrupt
.CONST    $frame_sync.USB_IN_STEREO_COPY_STRUC_SIZE                 10;


// USB Mono Input Copy constants
.CONST    $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD                 0;      // [In] USB input port
.CONST    $frame_sync.USB_IN_MONO_COPY_SINK_FIELD                   1;      // [In] Audio output cbuffer
.CONST    $frame_sync.USB_IN_MONO_COPY_PACKET_LENGTH_FIELD          2;      // [In] Length of "large" USB packet in bytes (e.g. 96)
.CONST    $frame_sync.USB_IN_MONO_COPY_SHIFT_AMOUNT_FIELD           3;      // [In] Gain shift applied to the samples on output
.CONST    $frame_sync.USB_IN_MONO_COPY_LAST_HEADER_FIELD            4;      // Previous sync byte received (0..0x7f)
.CONST    $frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD         5;      // [In] Packet sequence period in packets (e.g. 10 gives: 9 small, 1 large)
.CONST    $frame_sync.USB_IN_MONO_STATE_FIELD                       6;      // USB input state
.CONST    $frame_sync.USB_IN_MONO_PACKET_COUNTER_FIELD              7;      // Packet counter (0..$frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD - 1)
.CONST    $frame_sync.USB_IN_MONO_COPY_RETRY_FIELD                  8;      // Retry flag indicates attempt to read more than 1 USB packet on a timer interrupt
.CONST    $frame_sync.USB_IN_MONO_COPY_STRUC_SIZE                   9;


// USB Stereo Output Operator constants
.CONST    $frame_sync.USB_OUT_STEREO_LEFT_SOURCE_FIELD              0;
.CONST    $frame_sync.USB_OUT_STEREO_RIGHT_SOURCE_FIELD             1;
.CONST    $frame_sync.USB_OUT_STEREO_SINK_FIELD                     2;
.CONST    $frame_sync.USB_OUT_STEREO_SHIFT_AMOUNT_FIELD             3;
.CONST    $frame_sync.USB_OUT_STEREO_TRANSFER_PER_PERIOD_FIELD      4;
.CONST    $frame_sync.USB_OUT_STEREO_STALL_CNT_FIELD                5;
.CONST    $frame_sync.USB_OUT_STEREO_STRUC_SIZE                     6;


 // USB mono Output Operator constants
.CONST    $frame_sync.USB_OUT_MONO_SOURCE_FIELD                     0;
.CONST    $frame_sync.USB_OUT_MONO_SINK_FIELD                       1;
.CONST    $frame_sync.USB_OUT_MONO_SHIFT_AMOUNT_FIELD               2;
.CONST    $frame_sync.USB_OUT_MONO_TRANSFER_PER_PERIOD_FIELD        3;
.CONST    $frame_sync.USB_OUT_MONO_STALL_CNT_FIELD                  4;
.CONST    $frame_sync.USB_OUT_MONO_STRUC_SIZE                       5;

.CONST    $frame_sync.IDLE_STATE                                    0;
.CONST    $frame_sync.SYNCING_A_STATE                               1;
.CONST    $frame_sync.SYNCING_B_STATE                               2;
.CONST    $frame_sync.SYNCED_STATE                                  3;

#endif
