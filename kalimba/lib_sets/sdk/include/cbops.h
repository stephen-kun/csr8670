// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1894100 $  $DateTime: 2014/05/09 10:06:38 $
// *****************************************************************************

#ifndef CBOPS_HEADER_INCLUDED
#define CBOPS_HEADER_INCLUDED

// ** core copy values **

   .CONST   $cbops.MAX_NUM_CHANNELS                                 16;
   .CONST   $cbops.NO_MORE_OPERATORS                                -1;
   .CONST   $cbops.MAX_OPERATORS                                    10;
   .CONST   $cbops.MAX_COPY_SIZE                                    512;


   // ** operator framework parameters **
   .CONST   $cbops.OPERATOR_STRUC_ADDR_FIELD                        0;
   .CONST   $cbops.NUM_INPUTS_FIELD                                 1;



   // ** operator structure parameters **
   .CONST   $cbops.NEXT_OPERATOR_ADDR_FIELD                         0;
   .CONST   $cbops.FUNCTION_VECTOR_FIELD                            1;
   .CONST   $cbops.PARAMETER_AREA_START_FIELD                       2;
   .CONST   $cbops.STRUC_SIZE                                       3;


   // ** function vector parameters **
   #include "cbops_vector_table.h"

   // ** dc remove operator fields **
   #include "operators/cbops_dc_remove.h"

   // ** limited copy operator fields **
   #include "operators/cbops_limited_copy.h"

   // ** fill limit operator fields **
   #include "operators/cbops_fill_limit.h"

   // ** noise gate operator fields **
   #include "operators/cbops_noise_gate.h"

   // ** shift operator fields **
   #include "operators/cbops_shift.h"

   // ** side tone copy operator fields **
   #include "operators/cbops_sidetone_mix.h"

   // ** silence and clipping detect fields **
   #include "operators/cbops_silence_clip_detect.h"

   // ** upsample and mix operator fields **
   #include "operators/cbops_upsample_mix.h"

   // ** volume operator fields **
   #include "operators/cbops_volume.h"

   // ** new volume fields **
   #include "operators/cbops_volume_basic.h"

   // ** warp and shift operator fields **
   #include "operators/cbops_warp_and_shift.h"

   // ** de-interleave operator fields **
   #include "operators/cbops_deinterleave.h"

   // ** rate adjustment and shift fields **
   #include "operators/cbops_rate_adjustment_and_shift.h"

   // ** mono to stereo copy fields **
   #include "operators/cbops_one_to_two_chan_copy.h"

   // ** copy fields **
   #include "operators/cbops_copy_op.h"

   // ** copy fields **
   #include "operators/cbops_compress_copy_op.h"

   // ** mix fields **
   #include "operators/cbops_mix.h"

   // ** mono to stereo operator fields **
   #include "operators/cbops_mono_to_stereo.h"

   // ** 3D sound effect onto stereo sound fields **
   #include "operators/cbops_stereo_3d_enhance_op.h"

   // ** status check gain fields **
   #include "operators/cbops_status_check_gain.h"

   // ** scale fields **
   #include "operators/cbops_scale.h"

   // ** stereo to mono copy fields **
   #include "operators/cbops_two_to_one_chan_copy.h"

   // ** equalizer fields **
   #include "operators/cbops_eq.h"

   #include "operators/resample/resample_header.h"
   // ** dither and shift operator
   #include "operators/cbops_dither_and_shift.h"

   // ** universal mixer fields **
   #include "operators/cbops_univ_mix_op.h"

   // ** stereo to mono convertor fields **
   #include "operators/cbops_s_to_m_op.h"

   // ** cross mix operator fields **
   #include "operators/cbops_cross_mix.h"

    // ** user filter operator fields **
   #include "operators/cbops_user_filter.h"

   #include "operators/iir_resample/iir_resample_header.h"
   // ** iir resampler (Verserion 2) operator fields **
   #include "operators/iir_resamplev2/iir_resamplev2_header.h"

   // ** fixed amount operator fields **
   #include "operators/cbops_fixed_amount.h"

   #include "operators/cbops_signal_detect.h"
   #include "operators/cbops_stereo_soft_mute.h"
   #include "operators/cbops_soft_mute.h"
   #include "operators/cbops_switch.h"
   #include "operators/cbops_delay.h"
#endif // CBOPS_HEADER_INCLUDED
