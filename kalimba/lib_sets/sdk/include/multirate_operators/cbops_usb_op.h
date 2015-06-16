// *****************************************************************************
// %%fullcopyright(2005)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef CBOPS_USB_HEADER_INCLUDED
#define CBOPS_USB_HEADER_INCLUDED

.CONST   $cbops.usb_in_op.INPUT_INDEX_FIELD                0;
.CONST   $cbops.usb_in_op.OUTPUT1_INDEX_FIELD              1;
.CONST   $cbops.usb_in_op.OUTPUT2_INDEX_FIELD              2;
.CONST   $cbops.usb_in_op.PKT_LENGTH_FIELD                 3;
.CONST   $cbops.usb_in_op.LAST_HEADER_FIELD                4;
.CONST   $cbops.usb_in_op.STRUC_SIZE                       5;

.CONST   $cbops.usb_out_op.INPUT1_INDEX_FIELD              0;
.CONST   $cbops.usb_out_op.INPUT2_INDEX_FIELD              1;
.CONST   $cbops.usb_out_op.OUTPUT_INDEX_FIELD              2;
.CONST   $cbops.usb_out_op.PACKET_PERIOD_FIELD             3;
.CONST   $cbops.usb_out_op.STALL_COUNT_FIELD               4;
.CONST   $cbops.usb_out_op.LAST_LIMIT_FIELD                5;
.CONST   $cbops.usb_out_op.PACKET_BUFFER_DATA_FIELD        6;
.CONST   $cbops.usb_out_op.PACKET_BUFFER_START_FIELD       7;
.CONST   $cbops.usb_out_op.STRUC_SIZE                      7;

// USB stall count threshold
.CONST $CBOPS_USB_STALL_CNT_THRESH                         7;

#define CBOPS_USB_OUT_MONO_STRUC_SIZE(x)     ( $cbops.usb_out_op.STRUC_SIZE + 1 + (x)/1000)
#define CBOPS_USB_OUT_STEREO_STRUC_SIZE(x)   ( $cbops.usb_out_op.STRUC_SIZE + 1 + (x)/500)


#endif // CBOPS_USB_HEADER_INCLUDED