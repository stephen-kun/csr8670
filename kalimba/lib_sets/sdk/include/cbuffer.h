// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1921919 $  $DateTime: 2014/06/18 21:18:28 $
// *****************************************************************************

#ifndef CBUFFER_HEADER_INCLUDED
#define CBUFFER_HEADER_INCLUDED

   .CONST    $cbuffer.SIZE_FIELD           0;
   .CONST    $cbuffer.READ_ADDR_FIELD      1;
   .CONST    $cbuffer.WRITE_ADDR_FIELD     2;
   #ifdef BASE_REGISTER_MODE
      .CONST    $cbuffer.START_ADDR_FIELD     3;
      .CONST    $cbuffer.STRUC_SIZE           4;
   #else
      .CONST    $cbuffer.STRUC_SIZE           3;
   #endif


	// Frame Buffer for Processing Modules
	.CONST	$frmbuffer.CBUFFER_PTR_FIELD	0;
	.CONST	$frmbuffer.FRAME_PTR_FIELD		1;
	.CONST	$frmbuffer.FRAME_SIZE_FIELD		2;
	.CONST  $frmbuffer.STRUC_SIZE           3;


   // MMU port identifier masks
#if defined(KAL_ARCH5)
   // -- rick --
   .CONST    $cbuffer.NUM_PORTS                   12;
   .CONST    $cbuffer.WRITE_PORT_OFFSET           0x00000C;
   .CONST    $cbuffer.PORT_NUMBER_MASK            0x00000F;
   .CONST    $cbuffer.TOTAL_PORT_NUMBER_MASK      0x00001F;
   .CONST    $cbuffer.TOTAL_CONTINUOUS_PORTS      12;

   .CONST    $cbuffer.MMU_PAGE_SIZE         64;
#elif defined(KAL_ARCH3)
   // -- BC7 onwards --
   #if defined(GORDON)
      .CONST    $cbuffer.NUM_PORTS                   12;
      .CONST    $cbuffer.WRITE_PORT_OFFSET           0x00000C;
      .CONST    $cbuffer.PORT_NUMBER_MASK            0x00000F;
      .CONST    $cbuffer.TOTAL_PORT_NUMBER_MASK      0x00001F;
      .CONST    $cbuffer.TOTAL_CONTINUOUS_PORTS      8;
   #else
      .CONST    $cbuffer.NUM_PORTS                   8;
      .CONST    $cbuffer.WRITE_PORT_OFFSET           0x000008;
      .CONST    $cbuffer.PORT_NUMBER_MASK            0x000007;
      .CONST    $cbuffer.TOTAL_PORT_NUMBER_MASK      0x00000F;
      .CONST    $cbuffer.TOTAL_CONTINUOUS_PORTS      8;
   #endif
   .CONST    $cbuffer.MMU_PAGE_SIZE         64;
#endif

   .CONST    $cbuffer.READ_PORT_MASK        0x800000;
   .CONST    $cbuffer.WRITE_PORT_MASK       $cbuffer.READ_PORT_MASK + $cbuffer.WRITE_PORT_OFFSET;


   // MMU port force masks
   // force 'endian' constants
   .CONST    $cbuffer.FORCE_ENDIAN_MASK               0x300000;
   .CONST    $cbuffer.FORCE_ENDIAN_SHIFT_AMOUNT       -21;
   .CONST    $cbuffer.FORCE_LITTLE_ENDIAN             0x100000;
   .CONST    $cbuffer.FORCE_BIG_ENDIAN                0x300000;

   // force 'sign extend' constants
   .CONST    $cbuffer.FORCE_SIGN_EXTEND_MASK          0x0C0000;
   .CONST    $cbuffer.FORCE_SIGN_EXTEND_SHIFT_AMOUNT  -19;
   .CONST    $cbuffer.FORCE_SIGN_EXTEND               0x040000;
   .CONST    $cbuffer.FORCE_NO_SIGN_EXTEND            0x0C0000;

   // force 'bit width' constants
   .CONST    $cbuffer.FORCE_BITWIDTH_MASK             0x038000;
   .CONST    $cbuffer.FORCE_BITWIDTH_SHIFT_AMOUNT     -16;
   .CONST    $cbuffer.FORCE_8BIT_WORD                 0x008000;
   .CONST    $cbuffer.FORCE_16BIT_WORD                0x018000;
   .CONST    $cbuffer.FORCE_24BIT_WORD                0x028000;
   .CONST    $cbuffer.FORCE_32BIT_WORD                0x038000;

   // force 'saturate' constants
   .CONST    $cbuffer.FORCE_SATURATE_MASK             0x006000;
   .CONST    $cbuffer.FORCE_SATURATE_SHIFT_AMOUNT     -14;
   .CONST    $cbuffer.FORCE_NO_SATURATE               0x002000;
   .CONST    $cbuffer.FORCE_SATURATE                  0x006000;

   // force 'padding' constants
   .CONST    $cbuffer.FORCE_PADDING_MASK              0x001C00;
   .CONST    $cbuffer.FORCE_PADDING_SHIFT_AMOUNT      -11;
   .CONST    $cbuffer.FORCE_PADDING_NONE              0x000400;
   .CONST    $cbuffer.FORCE_PADDING_LS_BYTE           0x000C00;
   .CONST    $cbuffer.FORCE_PADDING_MS_BYTE           0x001400;

   // force 'defaults for pcm audio' constants
   .CONST    $cbuffer.FORCE_PCM_AUDIO                 $cbuffer.FORCE_LITTLE_ENDIAN +
                                                      $cbuffer.FORCE_SIGN_EXTEND +
                                                      $cbuffer.FORCE_SATURATE;
   .CONST    $cbuffer.FORCE_24B_PCM_AUDIO             $cbuffer.FORCE_LITTLE_ENDIAN +
                                                      $cbuffer.FORCE_32BIT_WORD +
                                                      $cbuffer.FORCE_PADDING_MS_BYTE +
                                                      $cbuffer.FORCE_NO_SATURATE;
   // force 'defaults for raw 16bit data' constants
   .CONST    $cbuffer.FORCE_16BIT_DATA_STREAM         $cbuffer.FORCE_BIG_ENDIAN +
                                                      $cbuffer.FORCE_NO_SIGN_EXTEND +
                                                      $cbuffer.FORCE_NO_SATURATE;


#endif
