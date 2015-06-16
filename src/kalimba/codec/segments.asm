// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

.ifndef SEGMENTS_ASM_INCLUDED
.define SEGMENTS_ASM_INCLUDED

.if !defined(KALASM3)
// These will map the PM_DYNAMIC_x and _SCRATCH segments to "normal" groups
// link scratch memory segments to DMxGroups (for lib build only)
//          Name                 CIRCULAR?   Link Order  Group list
.DEFSEGMENT DM_SCRATCH                       5           DM1Group  DM2Group;
.DEFSEGMENT DM1_SCRATCH                      3           DM1Group;
.DEFSEGMENT DM2_SCRATCH                      3           DM2Group;
.DEFSEGMENT DMCIRC_SCRATCH       CIRCULAR    4           DM1Group  DM2Group;
.DEFSEGMENT DM1CIRC_SCRATCH      CIRCULAR    2           DM1Group;
.DEFSEGMENT DM2CIRC_SCRATCH      CIRCULAR    2           DM2Group;

// link dynamic program memory segments to CODEGroup (for lib build only)
//          Name                             Link Order  Group list
.DEFSEGMENT PM_DYNAMIC_1                     4           CODEGroup;
.DEFSEGMENT PM_DYNAMIC_2                     4           CODEGroup;
.DEFSEGMENT PM_DYNAMIC_3                     4           CODEGroup;
.DEFSEGMENT PM_DYNAMIC_4                     4           CODEGroup;
.DEFSEGMENT PM_DYNAMIC_5                     4           CODEGroup;
.DEFSEGMENT PM_DYNAMIC_6                     4           CODEGroup;
.DEFSEGMENT PM_DYNAMIC_7                     4           CODEGroup;
.DEFSEGMENT PM_DYNAMIC_8                     4           CODEGroup;
.DEFSEGMENT PM_DYNAMIC_9                     4           CODEGroup;

// This segment is not overlayed
.DEFSEGMENT DM_STATIC                        5           DM1Group  DM2Group;

//Module Mappings
// NOTE: All the levels are subjectively assigned and no actual 
// measurements have been performed
.define CODEC_STREAM_DECODE_PM            PM_DYNAMIC_6
.define CODEC_STREAM_DECODE_SYNC_PM       PM_DYNAMIC_6
.define CODEC_STREAM_ENCODE_PM            PM_DYNAMIC_8
.define CODEC_WRITE_RTP_HEADER_PM         PM_DYNAMIC_5
.define CODEC_GET_ENCODED_FRAME_INFO_PM   PM_DYNAMIC_3
.define CODEC_STREAM_RELAY_PM             PM_DYNAMIC_5
.endif

.endif
