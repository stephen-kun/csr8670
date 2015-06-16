// *****************************************************************************
// %%fullcopyright(2005)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef CBOPS_MULTIRATE_HEADER_INCLUDED
#define CBOPS_MULTIRATE_HEADER_INCLUDED

// ** core copy values **

   // ** operator framework parameters **
   .CONST   $cbops_multirate.BUFFER_TABLE_FIELD                     0;
   .CONST   $cbops_multirate.MAIN_FIRST_OPERATOR_FIELD              1;
   .CONST   $cbops_multirate.MTU_FIRST_OPERATOR_FIELD               2;
   .CONST   $cbops_multirate.NUM_INPUTS_FIELD                       3;

   // ** operator framework parameters **
   .CONST   $cbops_multirate.BufferTable.BUFFER_FIELD               0;
   .CONST   $cbops_multirate.BufferTable.POINTER_FIELD              1;
   .CONST   $cbops_multirate.BufferTable.TRANSFER_FIELD             2;
   .CONST   $cbops_multirate.BufferTable.ENTRY_SIZE                 3;

   // ** operator structure parameters **
   .CONST   $cbops_multirate.MTU_NEXT_OPERATOR_FIELD                0;
   .CONST   $cbops_multirate.MAIN_NEXT_OPERATOR_FIELD               1;
   .CONST   $cbops_multirate.FUNCTION_VECTOR_FIELD                  2;
   .CONST   $cbops_multirate.PARAMETER_AREA_START_FIELD             3;
   .CONST   $cbops_multirate.STRUC_SIZE                             4;

   .CONST   $cbops.NO_MORE_OPERATORS                                -1;
   
   // ** function vector parameters **
#include "cbops_vector_table.h"

// ** iir resampler (Verserion 2) operator fields **
#include "multirate_operators/cbops_copy_op.h"
#include "multirate_operators/cbops_shift.h"
#include "multirate_operators/cbops_dither_and_shift.h"
#include "multirate_operators/cbops_rate_adjustment_and_shift.h"
#include "multirate_operators/cbops_switch_op.h"
#include "multirate_operators/cbops_compress_copy_op.h"
#include "multirate_operators/cbops_dc_remove.h"
#include "multirate_operators/cbops_av_copy_op.h"
#include "multirate_operators/cbops_stereo_sync_op.h"

#include "multirate_operators/cbops_sidetone_filter_operator.h"
#include "multirate_operators/cbops_sidetone_mix_operator.h"
#include "multirate_operators/cbops_hw_warp_operator.h"   
#include "multirate_operators/cbops_aux_mix_operator.h"   
#include "multirate_operators/cbops_port_wrap_op.h"
#include "multirate_operators/cbops_insert_op.h"
#include "multirate_operators/cbops_rate_moniter_op.h"
#include "multirate_operators/cbops_usb_op.h"
#include "multirate_operators/cbops_conditional_op.h"
#include "multirate_operators/cbops_s_to_m_op.h"
#include "multirate_operators/cbops_soft_mute_op.h"
#include "multirate_operators/cbops_cmpd_op.h"
#include "multirate_operators/cbops_eq.h"
#include "multirate_operators/cbops_stereo_3d_enhancement.h"
#include "multirate_operators/cbops_volume.h"
#include "multirate_operators/cbops_peak_monitor_op.h"
#include "multirate_operators/cbops_signal_detect.h"
#include "multirate_operators/cbops_deinterleave_mix.h"
#include "multirate_operators/cbops_fir_resample.h"
#include "multirate_operators/iir_resamplev2/iir_resamplev2_header.h"


#endif // CBOPS_MULTIRATE_HEADER_INCLUDED
