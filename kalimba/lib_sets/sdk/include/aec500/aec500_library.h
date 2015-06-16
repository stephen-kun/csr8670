// *****************************************************************************
// %%fullcopyright(2007)        http://www.csr.com
// %%version
//
// $Change$  $DateTime$
// *****************************************************************************

#ifndef AEC_500_LIB_H_INCLUDED
#define AEC_500_LIB_H_INCLUDED
// *****************************************************************************
// This library implements the Hands-Free-Kit system based on the
//   matlab algoritm version 4.8.1
// *****************************************************************************

// Version of Library
.CONST  $AEC_500_VERSION                       0x001000;

// Call State
.CONST $M.AEC_500.CALLST.CONNECTING            2;

// upper-bound for full-band log power Q8.16
.CONST $M.AEC_500.AEC_L2Px_HB					0xF80000;

// log2(1.0/(Na_t*fs/L))  signed Q8.16
.CONST  $M.AEC_500.L_MUA_ON						0xFF0000;
.CONST  $M.AEC_500_HF.L_MUA_ON					0xFD0000;

// log2(1-exp(-1/Na_sb)) : signed Q8.16
.CONST $M.AEC_500.L_ALFA_A					0xFEA782;
.CONST $M.AEC_500_HF.L_ALFA_A				0xFCE929;

// sqrt(1.5*L/M) Q2.22
.CONST $M.AEC_500.CNG_G_ADJUST				0x727C97;     // SP.  Change due to frame size

// Number of Auxillary FNMLS taps
.CONST $M.AEC_500.Num_Auxillary_Taps            0;
.CONST $M.AEC_500_HF.Num_Auxillary_Taps         3;

.CONST $M.AEC_500.Num_Primary_Taps              2;
.CONST $M.AEC_500_HF.Num_Primary_Taps           8;

.CONST $M.AEC_500.RER_dim                       64;

// WB/NB Constants
.CONST $M.AEC_500_WB.Num_HFK_Freq_Bins				129;
.CONST $M.AEC_500_WB.LPwrX_margin.overflow_bits		-4; // allow magnitude up to 2048.0(Q8.16)
.CONST $M.AEC_500_WB.LPwrX_margin.scale_factor		(16.0/129.0);

.CONST $M.AEC_500_NB.Num_HFK_Freq_Bins				65;
.CONST $M.AEC_500_NB.LPwrX_margin.overflow_bits		-3; // allow magnitude up to 1024.0(Q8.16)
.CONST $M.AEC_500_NB.LPwrX_margin.scale_factor		(8.0/65.0);


// @DATA_OBJECT AECDATAOBJECT

// Input/Output Block Offsets
// SP.  Needs to match ADF
// @DOC_FIELD_TEXT Pointer to real part of E (AEC output)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_E_REAL_PTR            0;
// @DOC_FIELD_TEXT Pointer to imaginary part of E (AEC output)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_E_IMAG_PTR            $M.AEC_500.OFFSET_E_REAL_PTR +1;
// @DOC_FIELD_TEXT Pointer to block exponent of D/E (AEC send input/output)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_D_EXP_PTR             $M.AEC_500.OFFSET_E_IMAG_PTR+1;
// @DOC_FIELD_TEXT Pointer to real part of D (AEC send input)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_D_REAL_PTR            $M.AEC_500.OFFSET_D_EXP_PTR+1;
// @DOC_FIELD_TEXT Pointer to imaginary part of D (AEC send input)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_D_IMAG_PTR            $M.AEC_500.OFFSET_D_REAL_PTR +1;
// @DOC_FIELD_TEXT Pointer to a scratch memory in DM2 with size of '2*$M.CVC.Num_FFT_Freq_Bins + 1'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_SCRPTR_Exp_Mts_adapt  $M.AEC_500.OFFSET_D_IMAG_PTR+1;
//$AEC_500.rer_headset
//$AEC_500.rer_handsfree
//$AEC_500.rer_adfrnr
// @DOC_FIELD_TEXT RER exit function, to be initialized with '$AEC_500.rer_headset' or '$AEC_500.rer_handsfree'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_RER_EXT_FUNC_PTR      $M.AEC_500.OFFSET_SCRPTR_Exp_Mts_adapt+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.AEC_500.OFFSET_RER_D_REAL_PTR        $M.AEC_500.OFFSET_RER_EXT_FUNC_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.AEC_500.OFFSET_RER_D_IMAG_PTR        $M.AEC_500.OFFSET_RER_D_REAL_PTR +1;
// @DOC_FIELD_TEXT Pointer to imaginary part of Gr (RER internal complex array)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_Gr_imag           $M.AEC_500.OFFSET_RER_D_IMAG_PTR+1;
// @DOC_FIELD_TEXT Pointer to real part of Gr (RER internal complex array)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_Gr_real           $M.AEC_500.OFFSET_PTR_Gr_imag+1;
// @DOC_FIELD_TEXT Pointer to SqGr (RER internal real array)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_SqGr              $M.AEC_500.OFFSET_PTR_Gr_real+1;
// @DOC_FIELD_TEXT Pointer to L2absGr (RER internal real array)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_L2absGr           $M.AEC_500.OFFSET_PTR_SqGr+1;
// @DOC_FIELD_TEXT Pointer to LPwrD (RER internal real array)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_LPwrD             $M.AEC_500.OFFSET_PTR_L2absGr +1;
// @DOC_FIELD_TEXT Pointer to W_ri (RER internal interleaved complex array)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_SCRPTR_W_ri           $M.AEC_500.OFFSET_PTR_LPwrD +1;
// @DOC_FIELD_TEXT Pointer to L_adaptR (RER internal real array)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_SCRPTR_L_adaptR       $M.AEC_500.OFFSET_SCRPTR_W_ri +1;
// @DOC_FIELD_TEXT RER variation threshold, for handsfree only, default '0x040000' (Q8.16) (CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.AEC_500.OFFSET_RER_SQGRDEV           $M.AEC_500.OFFSET_SCRPTR_L_adaptR +1;

// SP. End of Match
// @DOC_FIELD_TEXT Pointer to real part of X (AEC receive input)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_X_REAL_PTR            $M.AEC_500.OFFSET_RER_SQGRDEV +1;
// @DOC_FIELD_TEXT Pointer to imaginary part of X (AEC receive input)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_X_IMAG_PTR            $M.AEC_500.OFFSET_X_REAL_PTR +1;
// @DOC_FIELD_TEXT Pointer to block exponent of X (AEC receive input)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_X_EXP_PTR             $M.AEC_500.OFFSET_X_IMAG_PTR +1;
// @DOC_FIELD_TEXT Pointer to G of send OMS (OMS1 for handsfree, i.e. pre-AEC OMS)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_OMS1_G_PTR            $M.AEC_500.OFFSET_X_EXP_PTR +1;
// @DOC_FIELD_TEXT Pointer to LpX_nz of send OMS (OMS1 for handsfree, i.e. pre-AEC OMS)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_OMS1_D_NZ_PTR         $M.AEC_500.OFFSET_OMS1_G_PTR +1;
// @DOC_FIELD_TEXT Pointer to G of send OMS (OMS1 for handsfree, i.e. pre-AEC OMS, set to '0' for 2mic headset)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_oms_adapt_G_PTR       $M.AEC_500.OFFSET_OMS1_D_NZ_PTR +1;
// @DOC_FIELD_TEXT Pointer to G of send OMS (OMS2 for handsfree, i.e. post-AEC OMS)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_OMS2_G_PTR            $M.AEC_500.OFFSET_oms_adapt_G_PTR +1;
// @DOC_FIELD_TEXT Send OMS aggressiveness, default 1.0 (Q1.23) (CVC parameter)
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS    $M.AEC_500.OFFSET_OMS2_G_PTR +1;
// @DOC_FIELD_TEXT CND gain, default 0x200000 (Q3.21) (CVC parameter)
// @DOC_FIELD_FORMAT Q3.21
.CONST $M.AEC_500.OFFSET_CNG_Q_ADJUST          $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS +1;
// @DOC_FIELD_TEXT Internal
.CONST $M.AEC_500.OFFSET_CNG_G_ADJUST          $M.AEC_500.OFFSET_CNG_Q_ADJUST +1;
// @DOC_FIELD_TEXT DTC aggressiveness, default 0.5 (Q1.23) (CVC parameter)
// @DOC_FIELD_FORMAT Q1.23
.CONST $M.AEC_500.OFFSET_DTC_AGRESSIVENESS     $M.AEC_500.OFFSET_CNG_G_ADJUST +1;
// @DOC_FIELD_TEXT RER internal, default 0.5
.CONST $M.AEC_500.OFFSET_RER_WGT_L2PXR         $M.AEC_500.OFFSET_DTC_AGRESSIVENESS +1;
// @DOC_FIELD_TEXT RER internal, default 0.5
.CONST $M.AEC_500.OFFSET_RER_WGT_L2PDR         $M.AEC_500.OFFSET_RER_WGT_L2PXR +1;
// @DOC_FIELD_TEXT Flag for repeating AEC filtering
// @DOC_FIELD_TEXT Set to '1' for handsfree
// @DOC_FIELD_TEXT Set to '0' for headset (CVC parameter)
// @DOC_FIELD_FORMAT Flag
.CONST $M.AEC_500.OFFSET_ENABLE_AEC_REUSE      $M.AEC_500.OFFSET_RER_WGT_L2PDR +1;
// @DOC_FIELD_TEXT CVC configuration (CVC parameter)
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.AEC_500.OFFSET_CONFIG                $M.AEC_500.OFFSET_ENABLE_AEC_REUSE +1;
// @DOC_FIELD_TEXT Maximum Power Margin, default 0x028000 (Q8.16) (CVC parameter for handsfree)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.AEC_500.OFFSET_MAX_LPWR_MARGIN       $M.AEC_500.OFFSET_CONFIG +1;

// @DOC_FIELD_TEXT AEC internal, set to '$M.AEC_500.Num_Auxillary_Taps'
.CONST $M.AEC_500.OFFSET_NUM_AUXILLARY_TAPS    $M.AEC_500.OFFSET_MAX_LPWR_MARGIN+1;
// @DOC_FIELD_TEXT AEC internal, set to '$M.AEC_500.Num_Primary_Taps'
.CONST $M.AEC_500.OFFSET_NUM_PRIMARY_TAPS      $M.AEC_500.OFFSET_NUM_AUXILLARY_TAPS+1;

// @DOC_FIELD_TEXT Number of FFT bins
// @DOC_FIELD_FORMAT Integer
.CONST $M.AEC_500.OFFSET_NUM_FREQ_BINS         $M.AEC_500.OFFSET_NUM_PRIMARY_TAPS+1;
// @DOC_FIELD_TEXT AEC internal, narrow/wide band specific
// @DOC_FIELD_TEXT for narrowband, set to '$M.AEC_500_NB.LPwrX_margin.overflow_bits'
// @DOC_FIELD_TEXT for wideband, set to '$M.AEC_500_WB.LPwrX_margin.overflow_bits'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_LPWRX_MARGIN_OVFL     $M.AEC_500.OFFSET_NUM_FREQ_BINS+1;
// @DOC_FIELD_TEXT AEC internal, narrow/wide band specific
// @DOC_FIELD_TEXT for narrowband, set to '$M.AEC_500_NB.LPwrX_margin.scale_factor'
// @DOC_FIELD_TEXT for wideband, set to '$M.AEC_500_WB.LPwrX_margin.scale_factor'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_LPWRX_MARGIN_SCL      $M.AEC_500.OFFSET_LPWRX_MARGIN_OVFL+1;


// @DOC_FIELD_TEXT Bit mask for enabling RERCBA, handsfree only
// @DOC_FIELD_FORMAT Bitmask
.CONST $M.AEC_500.OFFSET_RERCBA_ENABLE_MASK    $M.AEC_500.OFFSET_LPWRX_MARGIN_SCL+1;

// @DOC_FIELD_TEXT Handsfree only. RER aggresiveness. Default 0x200000 (Q6.18) (Handsfree CVC parameter)
// @DOC_FIELD_FORMAT Q6.18
.CONST $M.AEC_500.OFFSET_RER_AGGRESSIVENESS    $M.AEC_500.OFFSET_RERCBA_ENABLE_MASK+1;
// @DOC_FIELD_TEXT Handsfree only. RER weight. Default 0x200000 (Q3.21) (Handsfree CVC parameter)
// @DOC_FIELD_FORMAT Q3.21
.CONST $M.AEC_500.OFFSET_RER_WGT_SY            $M.AEC_500.OFFSET_RER_AGGRESSIVENESS+1;
// @DOC_FIELD_TEXT Handsfree only. RER offset. Default 0 (Q8.16) (Handsfree CVC parameter)
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.AEC_500.OFFSET_RER_OFFSET_SY         $M.AEC_500.OFFSET_RER_WGT_SY+1;
// @DOC_FIELD_TEXT Handsfree only. RER power. Default 2 (Q24.0) (Handsfree CVC parameter)
// @DOC_FIELD_FORMAT Integer
.CONST $M.AEC_500.OFFSET_RER_POWER             $M.AEC_500.OFFSET_RER_OFFSET_SY+1;
// @DOC_FIELD_TEXT Reference Power Threshold. Default set to '$M.AEC_500.AEC_L2Px_HB' (Q8.16)
// @DOC_FIELD_TEXT CVC parameter for handsfree
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.AEC_500.OFFSET_AEC_REF_LPWR_HB        $M.AEC_500.OFFSET_RER_POWER+1;

// wmsn: next 4 fields are for RERDT
// @DOC_FIELD_TEXT DTC status array for each frequency bins, scratch
// @DOC_FIELD_TEXT Size of Number of FFT bins
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_SCRPTR_RERDT_DTC       $M.AEC_500.OFFSET_AEC_REF_LPWR_HB+1;
// @DOC_FIELD_TEXT Threshold for DTC decision
// @DOC_FIELD_FORMAT Q8.16
.CONST $M.AEC_500.OFFSET_L2TH_RERDT_OFF         $M.AEC_500.OFFSET_SCRPTR_RERDT_DTC+1;
// @DOC_FIELD_TEXT RERDT aggressiveness
// @DOC_FIELD_FORMAT Q6.18
.CONST $M.AEC_500.OFFSET_RERDT_ADJUST           $M.AEC_500.OFFSET_L2TH_RERDT_OFF+1;
// @DOC_FIELD_TEXT Handsfree only. RERDT power.
// @DOC_FIELD_FORMAT Integer
.CONST $M.AEC_500.OFFSET_RERDT_POWER            $M.AEC_500.OFFSET_RERDT_ADJUST+1;

// SP. Moved from Static Memory
// @DOC_FIELD_TEXT Internal
// @DOC_FIELD_TEXT For headset, set to '$M.AEC_500.L_MUA_ON'
// @DOC_FIELD_TEXT For handsfree, set to '$M.AEC_500_HF.L_MUA_ON'
.CONST $M.AEC_500.OFFSET_AEC_L_MUA_ON		     $M.AEC_500.OFFSET_RERDT_POWER+1;
// @DOC_FIELD_TEXT Internal
// @DOC_FIELD_TEXT For headset, set to '$M.AEC_500.L_ALFA_A'
// @DOC_FIELD_TEXT For handsfree, set to '$M.AEC_500_HF.L_ALFA_A'
.CONST $M.AEC_500.OFFSET_AEC_L_ALFA_A          $M.AEC_500.OFFSET_AEC_L_MUA_ON+1;



// @DOC_FIELD_TEXT Internal
// @DOC_FIELD_TEXT For headset, set to '$M.AEC_500.dbl_talk_control_headset.normal_op'
// @DOC_FIELD_TEXT For handsfree, set to '$M.AEC_500.dbl_talk_control_handsfree.normal_op'
.CONST $M.AEC_500.OFFSET_DT_FUNC1_PTR          $M.AEC_500.OFFSET_AEC_L_ALFA_A+1;
// @DOC_FIELD_TEXT Internal
// @DOC_FIELD_TEXT For headset, set to '$M.AEC_500.dbl_talk_control_headset.normal_op_else'
// @DOC_FIELD_TEXT For handsfree, set to '$M.AEC_500.dbl_talk_control_handsfree.normal_op_else'
.CONST $M.AEC_500.OFFSET_DT_FUNC2_PTR          $M.AEC_500.OFFSET_DT_FUNC1_PTR+1;
// @DOC_FIELD_TEXT Internal
// @DOC_FIELD_TEXT For handsfree and 1mic headset set to '$AEC_500.handsfree_dtc_aggressiveness'
// @DOC_FIELD_TEXT For 2mic headset set to '0'
.CONST $M.AEC_500.OFFSET_DTC_AGRESS_FUNC_PTR   $M.AEC_500.OFFSET_DT_FUNC2_PTR+1;
// @DOC_FIELD_TEXT Internal
// @DOC_FIELD_TEXT For handsfree and 1mic headset set to '$AEC_500.LPwrX_update_handsfree'
// @DOC_FIELD_TEXT For 2mic headset set to '$AEC_500.LPwrX_update_headset'
.CONST $M.AEC_500.OFFSET_LPWRX_UPDT_FUNC_PTR   $M.AEC_500.OFFSET_DTC_AGRESS_FUNC_PTR+1;
// @DOC_FIELD_TEXT Internal
// @DOC_FIELD_TEXT For handsfree and 1mic headset set to '$M.AEC_500.divergence_control.func'
// @DOC_FIELD_TEXT For 2mic headset set to '0'
.CONST $M.AEC_500.OFFSET_RER_DIVERGE_FUNC_PTR  $M.AEC_500.OFFSET_LPWRX_UPDT_FUNC_PTR+1;

// @DOC_FIELD_TEXT Internal
// @DOC_FIELD_TEXT For headset, set to '$AEC_500.Const'
// @DOC_FIELD_TEXT For handsfree, set to '$AEC_500_HF.Const'
.CONST $M.AEC_500.OFFSET_CONST_DM1             $M.AEC_500.OFFSET_RER_DIVERGE_FUNC_PTR+1;

// Internal AEC Data - Pointers
// @DOC_FIELD_TEXT Pointer to real part of receive buffer, size of 'Num_FFT_Freq_Bins*Num_Primary_Taps'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_RcvBuf_real		  $M.AEC_500.OFFSET_CONST_DM1+1;
// @DOC_FIELD_TEXT Pointer to imaginary part of receive buffer, size of 'Num_FFT_Freq_Bins*Num_Primary_Taps'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_RcvBuf_imag		  $M.AEC_500.OFFSET_PTR_RcvBuf_real+1;
// @DOC_FIELD_TEXT Pointer to imaginary part of Ga, size of 'Num_FFT_Freq_Bins*Num_Primary_Taps'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_Ga_imag			  $M.AEC_500.OFFSET_PTR_RcvBuf_imag+1;
// @DOC_FIELD_TEXT Pointer to real part of Ga, size of 'Num_FFT_Freq_Bins*Num_Primary_Taps'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_Ga_real			  $M.AEC_500.OFFSET_PTR_Ga_imag+1;
// @DOC_FIELD_TEXT Pointer to imaginary part of Gb, size of 'RER_dim*Num_Auxillary_Taps'
// @DOC_FIELD_TEXT Handsfree only. For headset set to '0'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_Gb_imag			  $M.AEC_500.OFFSET_PTR_Ga_real+1;
// @DOC_FIELD_TEXT Pointer to real part of Gb, size of 'RER_dim*Num_Auxillary_Taps'
// @DOC_FIELD_TEXT Handsfree only. For headset set to '0'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_Gb_real			  $M.AEC_500.OFFSET_PTR_Gb_imag+1;
// @DOC_FIELD_TEXT Pointer to L2PxR (internal array, permanant), size of 4
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_L2PxR				  $M.AEC_500.OFFSET_PTR_Gb_real+1;
// @DOC_FIELD_TEXT Pointer to BExp_Ga (internal array, permanant), size of Num_FFT_Freq_Bins
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_BExp_Ga			  $M.AEC_500.OFFSET_PTR_L2PxR+1;
// @DOC_FIELD_TEXT Pointer to BExp_Gb (internal array, permanant), size of RER_dim
// @DOC_FIELD_TEXT Handsfree only. For headset set to '0'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_BExp_Gb			  $M.AEC_500.OFFSET_PTR_BExp_Ga+1;
// @DOC_FIELD_TEXT Pointer to LPwrX0 (internal array, permanant), size of Num_FFT_Freq_Bins
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_LPwrX0				  $M.AEC_500.OFFSET_PTR_BExp_Gb+1;
// @DOC_FIELD_TEXT Pointer to RatFE (internal array, permanant), size of RER_dim
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_RatFE				  $M.AEC_500.OFFSET_PTR_LPwrX0+1;
// @DOC_FIELD_TEXT Pointer to BExp_X_buf (internal array, permanant), size of 'Num_Primary_Taps+1'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_BExp_X_buf        $M.AEC_500.OFFSET_PTR_RatFE+1;
// @DOC_FIELD_TEXT Pointer to LpZ_nz (internal array, permanant), size of Num_FFT_Freq_Bins
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_LpZ_nz				  $M.AEC_500.OFFSET_PTR_BExp_X_buf+1;
// @DOC_FIELD_TEXT Pointer to LPwrX1 (internal array, permanant), size of Num_FFT_Freq_Bins
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_LPwrX1				  $M.AEC_500.OFFSET_PTR_LpZ_nz+1;

// Scratch
// @DOC_FIELD_TEXT Pointer to Attenuation (internal array, scratch in DM1), size of Num_FFT_Freq_Bins
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_SCRPTR_Attenuation	   $M.AEC_500.OFFSET_PTR_LPwrX1+1;
// @DOC_FIELD_TEXT Pointer to L_adaptA (internal array, scratch in DM1), size of Num_FFT_Freq_Bins
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_SCRPTR_L_adaptA		   $M.AEC_500.OFFSET_SCRPTR_Attenuation+1;
// @DOC_FIELD_TEXT Pointer to L_RatSqGt (internal array, scratch in DM2), size of RER_dim
// @DOC_FIELD_FORMAT Pointer
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_SCRPTR_L_RatSqGt	      $M.AEC_500.OFFSET_SCRPTR_L_adaptA+1;

// @DOC_FIELD_TEXT Internal, default -268
.CONST $M.AEC_500.OFFSET_L_DTC                  $M.AEC_500.OFFSET_SCRPTR_L_RatSqGt+1;
// @DOC_FIELD_TEXT, Comfort noise color selection -1=wht,0=brn,1=pnk,2=blu,3=pur (CVC parameter)
// @DOC_FIELD_FORMAT Flag
.CONST $M.AEC_500.OFFSET_CNG_NOISE_COLOR        $M.AEC_500.OFFSET_L_DTC+1;
// @DOC_FIELD_TEXT Pointer to set of noise shaping tables (q.14)
// @DOC_FIELD_TEXT For narrowband, set '$M.AEC_500.nb_constants.nzShapeTables'
// @DOC_FIELD_TEXT For wideband, set '$M.AEC_500.wb_constants.nzShapeTables'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500.OFFSET_PTR_NZ_TABLES          $M.AEC_500.OFFSET_CNG_NOISE_COLOR+1;
// pointer to currently selected noise shaping table (q.22)
.CONST $M.AEC_500.OFFSET_PTR_CUR_NZ_TABLE      $M.AEC_500.OFFSET_PTR_NZ_TABLES+1;


// Internal AEC Data - Variables
.CONST $M.AEC_500.OFFSET_L_RatSqG			      $M.AEC_500.OFFSET_PTR_CUR_NZ_TABLE+1;
.CONST $M.AEC_500.OFFSET_dL2PxFB				      $M.AEC_500.OFFSET_L_RatSqG+1;
.CONST $M.AEC_500.OFFSET_Exp_D					  $M.AEC_500.OFFSET_dL2PxFB+1;
.CONST $M.AEC_500.OFFSET_L2Pxt0					  $M.AEC_500.OFFSET_Exp_D+1;
.CONST $M.AEC_500.OFFSET_DTC_dLpX				  $M.AEC_500.OFFSET_L2Pxt0+1;
.CONST $M.AEC_500.OFFSET_DTC_LpXt_prev			  $M.AEC_500.OFFSET_DTC_dLpX+1;


.CONST $M.AEC_500.OFFSET_tt_dtc					  $M.AEC_500.OFFSET_DTC_LpXt_prev+1;
.CONST $M.AEC_500.OFFSET_ct_init			        $M.AEC_500.OFFSET_tt_dtc+1;
.CONST $M.AEC_500.OFFSET_ct_Px				     $M.AEC_500.OFFSET_ct_init+1;
.CONST $M.AEC_500.OFFSET_tt_cng				     $M.AEC_500.OFFSET_ct_Px+1;
.CONST $M.AEC_500.OFFSET_CNG_offset				  $M.AEC_500.OFFSET_tt_cng+1;
.CONST $M.AEC_500.OFFSET_RER_func				  $M.AEC_500.OFFSET_CNG_offset+1;
.CONST $M.AEC_500.OFFSET_dgStartPtr				  $M.AEC_500.OFFSET_RER_func+1;

.CONST $M.AEC_500.OFFSET_dg_control_Freq_Bins  $M.AEC_500.OFFSET_dgStartPtr+1;

.CONST $M.AEC_500.OFFSET_AEC_COUPLING          $M.AEC_500.OFFSET_dg_control_Freq_Bins+1;
.CONST $M.AEC_500.OFFSET_HD_L_AECgain          $M.AEC_500.OFFSET_AEC_COUPLING+1;

.CONST $M.AEC_500.OFFSET_LPXFB_RERDT           $M.AEC_500.OFFSET_HD_L_AECgain+1;

.CONST $M.AEC_500.STRUCT_SIZE                  $M.AEC_500.OFFSET_LPXFB_RERDT+1;

// @END  DATA_OBJECT AECDATAOBJECT



// FDNLP - (Handsfree)
.CONST $M.FDNLP_500.OFFSET_VSM_HB              0;
.CONST $M.FDNLP_500.OFFSET_VSM_LB              $M.FDNLP_500.OFFSET_VSM_HB+1;
.CONST $M.FDNLP_500.OFFSET_VSM_MAX_ATT         $M.FDNLP_500.OFFSET_VSM_LB+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_HB            $M.FDNLP_500.OFFSET_VSM_MAX_ATT+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_LB            $M.FDNLP_500.OFFSET_FDNLP_HB+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_MB            $M.FDNLP_500.OFFSET_FDNLP_LB+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_NBINS         $M.FDNLP_500.OFFSET_FDNLP_MB+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_ATT           $M.FDNLP_500.OFFSET_FDNLP_NBINS+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_ATT_THRESH    $M.FDNLP_500.OFFSET_FDNLP_ATT+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_ECHO_THRESH   $M.FDNLP_500.OFFSET_FDNLP_ATT_THRESH+1;
.CONST $M.FDNLP_500.STRUCT_SIZE                $M.FDNLP_500.OFFSET_FDNLP_ECHO_THRESH+1;


// @DATA_OBJECT NLPDATAOBJECT

// @DOC_FIELD_TEXT Pointer to real part of D (AEC send input)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_D_REAL_PTR         0;
// @DOC_FIELD_TEXT Pointer to imaginary part of D (AEC send input)
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_D_IMAG_PTR         $M.AEC_500_HF.OFFSET_D_REAL_PTR+1;
// @DOC_FIELD_TEXT Number of FFT bins
// @DOC_FIELD_FORMAT Integer
.CONST $M.AEC_500_HF.OFFSET_NUM_FREQ_BINS      $M.AEC_500_HF.OFFSET_D_IMAG_PTR+1;

// Half Duplex
// @DOC_FIELD_TEXT Half Duplex Threshold (CVC parameter)
// @DOC_FIELD_FORMAT Q12.12
.CONST $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN     $M.AEC_500_HF.OFFSET_NUM_FREQ_BINS+1;
// FDNLP - VSM
// @DOC_FIELD_TEXT Pointer to current system call state flag
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_CALLSTATE_PTR      $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN+1;
// @DOC_FIELD_TEXT Tier switch threshold (CVC parameter)
// @DOC_FIELD_FORMAT Q12.12
.CONST $M.AEC_500_HF.OFFSET_TIER2_THRESH       $M.AEC_500_HF.OFFSET_CALLSTATE_PTR+1;
// @DOC_FIELD_TEXT Tier state flag (output)
// @DOC_FIELD_FORMAT Flag
.CONST $M.AEC_500_HF.OFFSET_HC_TIER_STATE      $M.AEC_500_HF.OFFSET_TIER2_THRESH+1;

// @DOC_FIELD_TEXT Pointer to receive path signal VAD flag
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_PTR_RCV_DETECT     $M.AEC_500_HF.OFFSET_HC_TIER_STATE+1;

// @DOC_FIELD_TEXT Pointer to tier1 configuration parameter array
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_PTR_TIER1_CONFIG   $M.AEC_500_HF.OFFSET_PTR_RCV_DETECT+1;
// @DOC_FIELD_TEXT Pointer to tier2 configuration parameter array
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_PTR_TIER2_CONFIG   $M.AEC_500_HF.OFFSET_PTR_TIER1_CONFIG+1;

// @DOC_FIELD_TEXT Function pointer for howling control
// @DOC_FIELD_TEXT To enable: set '$AEC_500.ApplyHalfDuplex'
// @DOC_FIELD_TEXT To disable: set '0'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.HOWLING_CNTRL_FUNCPTR     $M.AEC_500_HF.OFFSET_PTR_TIER2_CONFIG+1;
// @DOC_FIELD_TEXT Function pointer for FDNLP
// @DOC_FIELD_TEXT To enable: set '$AEC_500.FdnlpProcess'
// @DOC_FIELD_TEXT To disable: set '0'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.FDNLP_FUNCPTR             $M.AEC_500_HF.HOWLING_CNTRL_FUNCPTR+1;
// @DOC_FIELD_TEXT Function pointer for VSM
// @DOC_FIELD_TEXT To enable: set '$AEC_500.VsmProcess'
// @DOC_FIELD_TEXT To disable: set '0'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.VSM_FUNCPTR               $M.AEC_500_HF.FDNLP_FUNCPTR+1;


// SP.  Allocated Data Pointers
// @DOC_FIELD_TEXT Pointer to RatFE, same array as used in AEC main object
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_PTR_RatFE				      $M.AEC_500_HF.VSM_FUNCPTR+1;
// @DOC_FIELD_TEXT Pointer to SqGr, same array as used in AEC main object
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_PTR_SqGr				       $M.AEC_500_HF.OFFSET_PTR_RatFE+1;

// @DOC_FIELD_TEXT Pointer to Attenuation, same array as used in AEC main object
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_SCRPTR_Attenuation	$M.AEC_500_HF.OFFSET_PTR_SqGr+1;
// @DOC_FIELD_TEXT Pointer to absGr, same array as used in AEC main object which is shared with 'L_adaptA'
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_SCRPTR_absGr       $M.AEC_500_HF.OFFSET_SCRPTR_Attenuation+1;
// @DOC_FIELD_TEXT Pointer to scratch memory with size of Num_FFT_Freq_Bins
// @DOC_FIELD_FORMAT Pointer
.CONST $M.AEC_500_HF.OFFSET_SCRPTR_temp		      $M.AEC_500_HF.OFFSET_SCRPTR_absGr+1;

// SP.  Internal FNDLP Data
.CONST $M.AEC_500_HF.OFFSET_PTR_CUR_CONFIG     $M.AEC_500_HF.OFFSET_SCRPTR_temp+1;
.CONST $M.AEC_500_HF.OFFSET_hd_ct_hold         $M.AEC_500_HF.OFFSET_PTR_CUR_CONFIG+$M.FDNLP_500.STRUCT_SIZE;
.CONST $M.AEC_500_HF.OFFSET_hd_att             $M.AEC_500_HF.OFFSET_hd_ct_hold+1;
.CONST $M.AEC_500_HF.OFFSET_G_vsm              $M.AEC_500_HF.OFFSET_hd_att+1;
.CONST $M.AEC_500_HF.OFFSET_fdnlp_cont_test    $M.AEC_500_HF.OFFSET_G_vsm+1;
.CONST $M.AEC_500_HF.OFFSET_mean_len           $M.AEC_500_HF.OFFSET_fdnlp_cont_test+1;
.CONST $M.AEC_500_HF.OFFSET_Vad_ct_burst       $M.AEC_500_HF.OFFSET_mean_len+1;
.CONST $M.AEC_500_HF.OFFSET_Vad_ct_hang        $M.AEC_500_HF.OFFSET_Vad_ct_burst+1; // must follow ct_burst

.CONST $M.AEC_500_HF.STRUCT_SIZE               $M.AEC_500_HF.OFFSET_Vad_ct_hang+1;

// @END  DATA_OBJECT NLPDATAOBJECT


// handsfree naming for SQGRDEV
.CONST $M.AEC_500.OFFSET_RER_VAR_THRESH        $M.AEC_500.OFFSET_RER_SQGRDEV;

// RERDT user parameter Default
.CONST $M.AEC_500.L2TH_RERDT_OFF       -20.0/128;  // Q8.16
.CONST $M.AEC_500.RERDT_ADJUST         6.0/32;     // Q6.18
.CONST $M.AEC_500.RERDT_POWER          1;


// @DATA_OBJECT MIC1AECDATAOBJECT
// Below must match AEC
// @DOC_FIELD_TEXT Internal
.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_E_REAL_PTR             0;
// @DOC_FIELD_TEXT Internal
.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_E_IMAG_PTR             $M.TWOMIC_AEC.OFFSET_FNLMS_E_REAL_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_EXP_PTR              $M.TWOMIC_AEC.OFFSET_FNLMS_E_IMAG_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_REAL_PTR             $M.TWOMIC_AEC.OFFSET_FNLMS_D_EXP_PTR+1;
// @DOC_FIELD_TEXT Internal
.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_IMAG_PTR             $M.TWOMIC_AEC.OFFSET_FNLMS_D_REAL_PTR+1;
// @DOC_FIELD_FORMAT Pointer
// @DOC_FIELD_TEXT Pointer to a scratch memory in DM2 with size of '2*$M.adf_alg_1_0_0.ADF_num_proc + 1'
.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt   $M.TWOMIC_AEC.OFFSET_FNLMS_D_IMAG_PTR + 1;
// End Match
.CONST $M.TWOMIC_AEC.OFFSET_PTR_MAIN_AEC                 $M.TWOMIC_AEC.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1              $M.TWOMIC_AEC.OFFSET_PTR_MAIN_AEC + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_Ga_real                  $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1 + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_Ga_imag                  $M.TWOMIC_AEC.OFFSET_PTR_Ga_real + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_BExp_Ga                  $M.TWOMIC_AEC.OFFSET_PTR_Ga_imag + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_real              $M.TWOMIC_AEC.OFFSET_PTR_BExp_Ga + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_imag              $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_real + 1;
// Size of the block
.CONST $M.TWOMIC_AEC.STRUCT_SIZE                         $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_imag + 1;
// @END  DATA_OBJECT MIC1AECDATAOBJECT

#endif
