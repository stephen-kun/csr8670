// *****************************************************************************
// %%fullcopyright(2005)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef CBOPS_SWITCH_HEADER_INCLUDED
#define CBOPS_SWITCH_HEADER_INCLUDED

   .CONST   $cbops.switch_op.PTR_STATE_FIELD             0;
   .CONST   $cbops.switch_op.MTU_NEXT_TRUE_FIELD         1;
   .CONST   $cbops.switch_op.MTU_NEXT_FALSE_FIELD        2;
   .CONST   $cbops.switch_op.MAIN_NEXT_TRUE_FIELD        3;
   .CONST   $cbops.switch_op.MAIN_NEXT_FALSE_FIELD       4;
   .CONST   $cbops.switch_op.STRUC_SIZE                  5;

   .CONST   $cbops.mux_1to2_op.PTR_STATE_FIELD           0;
   .CONST   $cbops.mux_1to2_op.NEXT_TRUE_FIELD           1;
   .CONST   $cbops.mux_1to2_op.NEXT_FALSE_FIELD          2;
   .CONST   $cbops.mux_1to2_op.STRUC_SIZE                3;


   .CONST   $cbops.demux_2to1_op.PTR_STATE_FIELD         0;
   .CONST   $cbops.demux_2to1_op.PREV_TRUE_FIELD         1;
   .CONST   $cbops.demux_2to1_op.PREV_FALSE_FIELD        2;
   .CONST   $cbops.demux_2to1_op.STRUC_SIZE              3;
#endif // CBOPS_SWITCH_HEADER_INCLUDED
