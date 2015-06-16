// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef cvc_sys_LIB_H
#define cvc_sys_LIB_H
#include "audio_proc_library.h"

.CONST $M.CVC.CONFIG.CODEC_CNTL_FUNC            0;
.CONST $M.CVC.CONFIG.CONFIG_FUNC                1;
.CONST $M.CVC.CONFIG.PERSIS_FUNC                2;
.CONST $M.CVC.CONFIG.SECURITY_ID                3;
.CONST $M.CVC.CONFIG.VERSION                    4;
.CONST $M.CVC.CONFIG.STANDBY_MODE               5;
.CONST $M.CVC.CONFIG.HFK_MODE                   6;
.CONST $M.CVC.CONFIG.NUM_MODES                  7;
.CONST $M.CVC.CONFIG.CALLST_MUTE                8;
.CONST $M.CVC.CONFIG.NUM_PARAMS                 9;
.CONST $M.CVC.CONFIG.PARAMS_PTR                 10;
.CONST $M.CVC.CONFIG.DEF_PARAMS_PTR             11;
.CONST $M.CVC.CONFIG.SYS_ID                     12;
.CONST $M.CVC.CONFIG.SYS_FS                     13;
.CONST $M.CVC.CONFIG.CVC_BANDWIDTH_INIT_FUNC    14;
.CONST $M.CVC.CONFIG.STATUS_PTR                 15;
.CONST $M.CVC.CONFIG.TONE_MIX_PTR               16;
.CONST $M.CVC.CONFIG.PTR_INV_DAC_TABLE          17;
.CONST $M.CVC.CONFIG.STRUC_SIZE                 18;

// VM Message IDs
.CONST $M.CVC.VMMSG.READY           0x1000;
.CONST $M.CVC.VMMSG.SETMODE         0x1001;
.CONST $M.CVC.VMMSG.VOLUME          0x1002;
.CONST $M.CVC.VMMSG.SETPARAM        0x1004;
.CONST $M.CVC.VMMSG.CODEC           0x1006;
.CONST $M.CVC.VMMSG.PING            0x1008;
.CONST $M.CVC.VMMSG.PINGRESP        0x1009;
.CONST $M.CVC.VMMSG.SECPASSED       0x100c;
.CONST $M.CVC.VMMSG.SETSCOTYPE      0x100d;
.CONST $M.CVC.VMMSG.GETPARAM        0x1010;
.CONST $M.CVC.VMMSG.GETPARAM_RESP   0x1011;
.CONST $M.CVC.VMMSG.LOADPARAMS      0x1012;
.CONST $M.CVC.VMMSG.SECFAILED       0x1013;
.CONST $M.CVC.VMMSG.LOADPERSIST     0x1014;
.CONST $M.CVC.VMMSG.LOADPERSIST_RESP 0x1015;
.CONST $M.CVC.VMMSG.STOREPERSIST    0x1016;

// SPI Message IDs
.CONST $M.CVC.SPIMSG.STATUS         0x1007;
.CONST $M.CVC.SPIMSG.PARAMS         0x1008;
.CONST $M.CVC.SPIMSG.REINIT         0x1009;
.CONST $M.CVC.SPIMSG.VERSION        0x100A;
.CONST $M.CVC.SPIMSG.CONTROL        0x100B;

// SSR Message IDs
.CONST $M.SSR.START                 0x1020;
.CONST $M.SSR.SET_CONFIG_VALUES     0x1021;


// System Control
.CONST $M.CVC_SYS.CONTROL.DAC_OVERRIDE              0x8000;
.CONST $M.CVC_SYS.CONTROL.CALLSTATE_OVERRIDE        0x4000;
.CONST $M.CVC_SYS.CONTROL.MODE_OVERRIDE             0x2000;

// System bandwidth
.CONST $M.CVC.BANDWIDTH.NB                      0;
.CONST $M.CVC.BANDWIDTH.UKN                     1;
.CONST $M.CVC.BANDWIDTH.FE                      2;
.CONST $M.CVC.BANDWIDTH.WB                      3;

.CONST $M.CVC.BANDWIDTH.NB_FS                   8000;
.CONST $M.CVC.BANDWIDTH.WB_FS                   16000;
.CONST $M.CVC.BANDWIDTH.FE_FS                   0;


#endif
