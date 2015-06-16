// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2007             http://www.csr.com
// Part of ADK 3.5
//
// $Revision$ $Date$
// *****************************************************************************

// *****************************************************************************
// FILE: sbadpcm.h - sub-band adpcm library internal header file
// *****************************************************************************

#ifndef _SBADPCM_H
#define _SBADPCM_H


// *****************************************************************************
// LIBRARY:
//    $M.Adpcm
//
// DESCRIPTION:
//
// MODIFICATIONS:
// *****************************************************************************

#define G722_BITEXACT 1
#define ENABLE_QMF_BYPASS 1

   #define SBADPCM_LIBRARY_VERSION                            0x010000
   


// *****************************************************************************
// DESCRIPTION:
//    SBADPCM encoder/decoder data object structure definition
//
// MODIFICATIONS:
// *****************************************************************************

   //---------------------------------------------------------------------------
   // Fields of the ADPCM front-end I/O PCM and mode specific configurations
   // User defined, must be set by the user through ADPCM initialization
   //---------------------------------------------------------------------------
   
   // Pointer to the front/end IO PCM process function
   .CONST $sbadpcm.decode.PTR_MODE_FIELD                           0;  
   .CONST $sbadpcm.decode.PTR_HIST_RECA_FIELD                      1;  
   .CONST $sbadpcm.decode.PTR_HIST_RECB_FIELD                      2;  
   .CONST $sbadpcm.decode.BLKSIZE_FIELD                            3;  

   .CONST $sbadpcm.encode.PTR_MODE_FIELD                           0;  
   .CONST $sbadpcm.encode.PTR_ENC_HISTX_FIELD                      1;
   .CONST $sbadpcm.encode.BLKSIZE_FIELD                            2;  
   .CONST $sbadpcm.encode.UNUSED_FIELD                             3;


   
   //---------------------------------------------------------------------------
   // SBADPCM internal state fields
   //---------------------------------------------------------------------------

   .CONST $sbadpcm.START_INTERNAL_FIELD       $sbadpcm.encode.UNUSED_FIELD+1;

   // upper sub band state (do not re-order)
   .CONST $sbadpcm.XL_FIELD               $sbadpcm.START_INTERNAL_FIELD;  
   .CONST $sbadpcm.EL_FIELD               $sbadpcm.XL_FIELD+1;    
   .CONST $sbadpcm.IL_FIELD               $sbadpcm.EL_FIELD+1;    
   .CONST $sbadpcm.DLt_FIELD              $sbadpcm.IL_FIELD+1;    
   .CONST $sbadpcm.NBL_FIELD              $sbadpcm.DLt_FIELD+1;    
   .CONST $sbadpcm.DETL_FIELD             $sbadpcm.NBL_FIELD+1;
   .CONST $sbadpcm.SL_FIELD               $sbadpcm.DETL_FIELD+1;
   .CONST $sbadpcm.SZL_FIELD              $sbadpcm.SL_FIELD+1;
   .CONST $sbadpcm.DLt_HIST_FIELD         $sbadpcm.SZL_FIELD+1;
   .CONST $sbadpcm.BL_FIELD               $sbadpcm.DLt_HIST_FIELD+7;
   .CONST $sbadpcm.PL_FIELD               $sbadpcm.BL_FIELD+6;
   .CONST $sbadpcm.AL_FIELD               $sbadpcm.PL_FIELD+2;
   .CONST $sbadpcm.RL_FIELD               $sbadpcm.AL_FIELD+2;
   
   

   // lower sub band state (do not re-order)
   .CONST $sbadpcm.XH_FIELD               $sbadpcm.RL_FIELD+2;
   .CONST $sbadpcm.EH_FIELD               $sbadpcm.XH_FIELD+1;
   .CONST $sbadpcm.IH_FIELD               $sbadpcm.EH_FIELD+1;
   .CONST $sbadpcm.DHt_FIELD              $sbadpcm.IH_FIELD+1;
   .CONST $sbadpcm.NBH_FIELD              $sbadpcm.DHt_FIELD+1;
   .CONST $sbadpcm.DETH_FIELD             $sbadpcm.NBH_FIELD+1;
   .CONST $sbadpcm.SH_FIELD               $sbadpcm.DETH_FIELD+1;
   .CONST $sbadpcm.SZH_FIELD              $sbadpcm.SH_FIELD+1;
   .CONST $sbadpcm.DH_HIST_FIELD          $sbadpcm.SZH_FIELD+1; 
   .CONST $sbadpcm.BH_FIELD               $sbadpcm.DH_HIST_FIELD+7; 
   .CONST $sbadpcm.PH_FIELD               $sbadpcm.BH_FIELD+6;
   .CONST $sbadpcm.AH_FIELD               $sbadpcm.PH_FIELD+2;
   .CONST $sbadpcm.RH_FIELD               $sbadpcm.AH_FIELD+2;

   
   // Size of 'sbadpcm' data object structure for a single instance. 
   // encoder and decoder structures are the same size.
   .CONST $sbadpcm.encode.STRUC_SIZE             $sbadpcm.RH_FIELD+2;
   .CONST $sbadpcm.decode.STRUC_SIZE             $sbadpcm.encode.STRUC_SIZE;


   // external history buffer size   
   .CONST $sbadpcm.HIST_BUF_SIZE         24;
   .CONST $sbadpcm.REC_HIST_BUF_SIZE     12;


   // Mode table format
   .CONST $sbadpcm.MODE_TABLE.FLAGS_FIELD           0;
   .CONST $sbadpcm.MODE_TABLE.PTRCONST_LSB_FIELD    1;
   .CONST $sbadpcm.MODE_TABLE.PTRTABLES_LSB_FIELD   2;
   .CONST $sbadpcm.MODE_TABLE.PTRCONST_HSB_FIELD    3;
   .CONST $sbadpcm.MODE_TABLE.PTRTABLES_HSB_FIELD   4;
   .CONST $sbadpcm.MODE_TABLE.STRUCT_SIZE           5;
   
   
   // flags
   .CONST $sbadpcm.flags.MODE_ENCODE     1; // "1" value signifies an encoder structure
   .CONST $sbadpcm.flags.BYPASS_QMF      2; // I/O is splitband, not 16k pcm (used for conformance testing)
   
   
   

   // relative indexes for generic LSB/HSB internal indexing
   // name                                 offset                      format
   //
   .CONST $sbadpcm.X_FIELD_OFFSET         0;                             // Q1.23 (rx on decoder)
   .CONST $sbadpcm.Ex_FIELD_OFFSET        $sbadpcm.X_FIELD_OFFSET+1;     // Q1.23 (dx on decoder)
   .CONST $sbadpcm.Ix_FIELD_OFFSET        $sbadpcm.Ex_FIELD_OFFSET+1;    // int 0-31
   .CONST $sbadpcm.Dxt_FIELD_OFFSET       $sbadpcm.Ix_FIELD_OFFSET+1;    // Q1.23
   .CONST $sbadpcm.NBx_FIELD_OFFSET       $sbadpcm.Dxt_FIELD_OFFSET+1;   // Q1.23
   .CONST $sbadpcm.DETx_FIELD_OFFSET      $sbadpcm.NBx_FIELD_OFFSET+1;   // Q1.15/8
   .CONST $sbadpcm.Sx_FIELD_OFFSET        $sbadpcm.DETx_FIELD_OFFSET+1;  // Q1.23
   .CONST $sbadpcm.SZx_FIELD_OFFSET       $sbadpcm.Sx_FIELD_OFFSET+1;    // Q1.23
   .CONST $sbadpcm.Dxt_HIST_FIELD_OFFSET  $sbadpcm.SZx_FIELD_OFFSET+1;     // Q1.23 overwrite of 1
   .CONST $sbadpcm.Bx_FIELD_OFFSET        $sbadpcm.Dxt_HIST_FIELD_OFFSET+7; // Q1.23
   .CONST $sbadpcm.Px_FIELD_OFFSET        $sbadpcm.Bx_FIELD_OFFSET+6;  // Q1.23   
   .CONST $sbadpcm.Ax_FIELD_OFFSET        $sbadpcm.Px_FIELD_OFFSET+2;  // Q1.23
   .CONST $sbadpcm.Rx_FIELD_OFFSET        $sbadpcm.Ax_FIELD_OFFSET+2;  // Q1.23
      
   
   

// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Object_initialize
//
// FUNCTION:
//    $sbadpcm.reset
//
// DESCRIPTION:
//    Initialize SBADPCM data object
//
// MODIFICATIONS:
//    6/15/09    scg - original implementation
//
// INPUTS:
//    r8 - pointer to ADPCM data object (encoder/decoder)
//    
// OUTPUTS:
//    None
//
// TRASHED REGISTERS:
//    r0-r1,r10,I0-I2, LOOP, L0,L1,M1
//
// RESERVED REGISTERS:
//    r8  - pointer to data object
//    L4  - length of circular buffer (I4)
//
// CPU USAGE:
//    D-MEMORY: 0
//    P-MEMORY: 31
//    CYCLES:   meaningless
//
// NOTES:
// *****************************************************************************


// *****************************************************************************
// MODULE:
//    $M.Adpcm.Encoder
//
// FUNCTION:
//    $adpcm.encoder.block_encode
//
// DESCRIPTION:
//    Coding PCM sample stream (I4,L4) into ADPCM code stream, in-place
//
//    Input Linear PCM samples are assumed to be left-justified (ie Q1.23)
//    Multiplexed SBADPCM output codes are stored in even words starting at I4/L4 
//
// MODIFICATIONS:
//    6/15/09    scg - original implementation
//
// INPUTS:
//    r10 - number of codes (non-zero)
//    r8  - pointer to data object (encoder)
//    I4  - i/o data pointer
//    L4  - length of circular buffer (I4)
//
// OUTPUTS:
//    I4  - Updated i/o buffer pointer for next block
//
// RESERVED REGISTERS:
//    r8  - pointer to data object
//    L4  - length of circular buffer (I4)
//
// TRASHED REGISTERS:
//    r0-r7,r10,rMAC,I0-I7,L0-L3,M0-M3,LOOP
//
// CPU USAGE:
//    D-MEMORY: 0
//    P-MEMORY: 49
//    CYCLES:   
//        bitexact: 7 + r10 * (42 + QMF_analysis + Quant_LSBenc + Quant_HSBenc + 2*Pred)
//         = 7 + r10 * (42 + 63 + 157 + 45 + 364) = 7+r10*671 : MIPS=5.4
//
// NOTES:
// *****************************************************************************


// *****************************************************************************
// MODULE:
//    $M.SBAdpcm.Decoder
//
// FUNCTION:
//    $sbadpcm.decoder.block_decode
//
// DESCRIPTION:
//    Decoding SBADPCM code stream (I4,L4) into PCM sample stream, in-place
//
//    Multiplexed SBADPCM input codes are stored in even words starting at I4/L4
//    Output Linear PCM samples are left-justified
//
// MODIFICATIONS:
//    7/06/09    scg - original implementation
//
// INPUTS:
//    r10 - number of codes (non-zero)
//    r8  - pointer to data object (decoder)
//    I4  - i/o data pointer
//    L4  - length of circular buffer (I4)
//
// OUTPUTS:
//    I4  - Updated i/o buffer pointer for next block
//
// RESERVED REGISTERS:
//    r8  - pointer to data object
//    L4  - length of circular buffer (I4)
//
// TRASHED REGISTERS:
//    r0-r7,r10,rMAC,I0-I7,L0-L3,M0-M3,LOOP
//
// CPU USAGE:
//    D-MEMORY: 0
//    P-MEMORY: 46
//    CYCLES:  
//      bitexact: 6 + r10 * (40 + Quant_LSBdec + Quant_HSBdec + 2*Pred + QMF_synth)
//       = 6 + r10 * (40 + 30 + 23 + 364 + 73) = 6+r10*530 : MIPS=4.2
//
// NOTES:
// *****************************************************************************

#endif // _SBADPCM_H
