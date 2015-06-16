// *****************************************************************************
// %%fullcopyright(2008)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************
#ifndef USER_EQ_HEADER_INCLUDED
#define USER_EQ_HEADER_INCLUDED


#include "cbuffer.h"

    .const $user_eq.num_bands                      0;
    .const $user_eq.pre_gain                       1;
    
    // filter types
    
    .const $user_eq.filter_type.bypass             0;
        
    .const $user_eq.filter_type.lp_1               1;
    .const $user_eq.filter_type.hp_1               2;
    .const $user_eq.filter_type.ap_1               3;
        
    .const $user_eq.filter_type.ls_1               4;
    .const $user_eq.filter_type.hs_1               5;
    .const $user_eq.filter_type.tlt_1              6;

    .const $user_eq.filter_type.lp_2               7;
    .const $user_eq.filter_type.hp_2               8;
    .const $user_eq.filter_type.ap_2               9;
        
    .const $user_eq.filter_type.ls_2              10;
    .const $user_eq.filter_type.hs_2              11;
    .const $user_eq.filter_type.tlt_2             12;
        
    .const $user_eq.filter_type.peq               13;
    
    // filter parameter constants
    
    .const $user_eq.freq_param_scale               3;
    .const $user_eq.gain_param_scale              60;
    .const $user_eq.q_param_scale                 12;
    
    // master gain limits
    .const $user_eq.gain_lo_gain_limit         -2160;       // -36 dB
    .const $user_eq.gain_hi_gain_limit           720;       // +12 dB
        
    // first order xp filter limits
    .const $user_eq.xp_1_lo_freq_limit             1;       // 0.3 Hz
    .const $user_eq.xp_1_hi_freq_limit         60000;       // 20 kHz
        
    // second order xp filter limits
    .const $user_eq.xp_2_lo_freq_limit           120;       // 40 Hz
    .const $user_eq.xp_2_hi_freq_limit         60000;       // 20 kHz
    .const $user_eq.xp_2_lo_q_limit           0x0400;       // 0.25
    .const $user_eq.xp_2_hi_q_limit           0x2000;       // 2.0
    
    // first order shelf limits
    .const $user_eq.shelf_1_lo_freq_limit         60;       // 20 Hz
    .const $user_eq.shelf_1_hi_freq_limit      60000;       // 20 kHz
    .const $user_eq.shelf_1_lo_gain_limit       -720;       // -12 dB
    .const $user_eq.shelf_1_hi_gain_limit        720;       // +12 dB
        
    // second order shelf limits
    .const $user_eq.shelf_2_lo_freq_limit        120;       // 40 Hz
    .const $user_eq.shelf_2_hi_freq_limit      60000;       // 20 kHz
    .const $user_eq.shelf_2_lo_gain_limit       -720;       // -12 dB
    .const $user_eq.shelf_2_hi_gain_limit        720;       // +12 dB
    .const $user_eq.shelf_2_lo_q_limit        0x0400;       // 0.25
    .const $user_eq.shelf_2_hi_q_limit        0x2000;       // 2.0
        
    // parametric filter limits
    .const $user_eq.peq_lo_freq_limit             60;       // 20 Hz
    .const $user_eq.peq_hi_freq_limit          60000;       // 20 kHz
    .const $user_eq.peq_lo_gain_limit          -2160;       // -36 dB
    .const $user_eq.peq_hi_gain_limit            720;       // +12 dB
    .const $user_eq.peq_lo_q_limit            0x0400;       // 0.25
    .const $user_eq.peq_hi_q_limit            0x8000;       // 8.0


#endif // USER_EQ_HEADER_INCLUDED
