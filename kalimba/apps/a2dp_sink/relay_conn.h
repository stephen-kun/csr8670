// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc %%copyright(2003)        http://www.csr.com
// %%version
//
// $Revision: #3 $  $Date: 2014/05/12 $
// *****************************************************************************

#ifndef TWS_HEADER_INCLUDED
#define TWS_HEADER_INCLUDED

#define $RELAY_CBUFFER_SIZE  3096
#define DELAY_LEN 1000
#define $DATA_NOT_SCHEDULED   0xff00ff
#define $DATA_SCHEDULED       0x000800
#define $MODE_MASK            0x0000ff
#define $VERSION_MASK         0xff0000
#define $LOW_BITPOOL          19
#define $HIGH_BITPOOL         53
#define SOFT_MUTE_TIMER       20000  
#define $ROLE_REVERSAL_THRESHOLD 100


.CONST  $RELAY_PORT                                      ($cbuffer.WRITE_PORT_MASK + 4);
.CONST  $TWS_ALIGNMENT_DELAY                             11000;
.CONST  $TWS_SYNC_TOLERANCE                              500; // number of microseconds before syncrhonisation delay on slave is reset                         
.CONST  $ROLE_TIMEOUT                                    1200; // threshold for 2 minute role monitoring period
.CONST  $TWS_RELAY_TIMEOUT                               8-1; // 8*1.5 ms = 12 ms (-1 becasue we start counting at0)
.CONST  $TWS_CHUNK_SIZE                                  672; //Used for sive based relay chunking
.CONST  $TWS_CONNECTION_HOLDOFF                          0; // # of frames to wait for link to settle
.CONST  $TWS_STANDALONE_CNT                              100; // # of frames to distinguish standalone and simultaneous operation
.CONST  $TWS_SOFTMUTE_TIME                               500000; //500 ms of mute...
.CONST  $TWS_ROUTING_MUTE_TIME                           40000; // 40 ms

.CONST  $UNKNOWN                                         0;
.CONST  $SLAVE                                           1;
.CONST  $MASTER                                          2;



   // SHAREME Relay Message IDs
.CONST $MESSAGE_VM_STREAM_RELAY_MODE                              0x1028;
.CONST $MESSAGE_VM_STREAM_RELAY_MODE_ACK                          0x1024;
.CONST $MESSAGE_VM_TWS_ROUTING_MODE                               0x7157;
.CONST $MESSAGE_VM_DEVICE_TRIMS                                   0x7158;
.CONST $MESSAGE_VM_EXTERNAL_VOLUME_ENABLE                         0x7159;
.CONST $MESSAGE_DSP_VOLUME                                        0x715A;
.CONST $MESSAGE_DSP_TWS_ERROR                                     0x715B;


.CONST $TWS_VERSION_UNSUPPORTED                                    1;


.CONST $NO_RELAY_MODE                                              0;
.CONST $SHAREME_MODE                                               1;
.CONST $TWS_MASTER_MODE                                            2;
.CONST $TWS_SLAVE_MODE                                             3;
.CONST $ERR_RELAY_LOST                                             0xFFF0;
.CONST $ERR_UNSUPPORTED_MODE                                       0xFFFF;

.CONST $TWS_ROUTING_STEREO                                         0;
.CONST $TWS_ROUTING_LEFT                                           1;
.CONST $TWS_ROUTING_RIGHT                                          2;
.CONST $TWS_ROUTING_DMIX                                           3;   

.CONST $TWS_VOL_MESSAGE_SIZE                                       5;           
.CONST $TWS_V3_PROTOCOL_ID                                         0x030000;




.CONST $relay.INPUT_CBUFFER_FIELD                       0;
.CONST $relay.INTERNAL_CBUFFER_PTR_FIELD                1;
.CONST $relay.RELAY_CBUFFER_FIELD                       2;
.CONST $relay.AV_DECODE_STRUC_FIELD                     3;	
.CONST $relay.CODEC_GET_BITPOS                          4;
.CONST $relay.CODEC_GETBITS                             5;
.CONST $relay.TWS_HEADER_FIELD                          6;
.CONST $relay.IS_APTX_FIELD                             7;
.CONST $relay.struct_size                               8;

.CONST $tws.header.SIZE_FIELD                           0;
.CONST $tws.header.ID_FIELD                             1;
.CONST $tws.header.ROUTING_MODE_FIELD                   2;
.CONST $tws.header.PLAYBACK_TIME_FIELD                  3;
.CONST $tws.header.SRA_TARGET_RATE_FIELD                4;
.CONST $tws.header.SYS_VOL_FIELD                        5;
.CONST $tws.header.MASTER_VOL_FIELD                     6;
.CONST $tws.header.TONE_VOL_FIELD                       7;
.CONST $tws.header.TRIM_LEFT_FIELD                      8;
.CONST $tws.header.TRIM_RIGHT_FIELD                     9;
.CONST $tws.header.SRA_ACTUAL_RATE_FIELD               10;
.CONST $tws.header.struct_size                         11;


#if defined(TWS_ENABLE) && defined(HARDWARE_RATE_MATCH)
   #error "Hardware Rate Matching not supported in TWS"
#endif

#endif
