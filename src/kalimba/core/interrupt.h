// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef INTERRUPT_HEADER_INCLUDED
#define INTERRUPT_HEADER_INCLUDED

#ifdef DEBUG_ON
   #ifndef INTERRUPT_PROFILER_ON
      #define INTERRUPT_PROFILER_ON
   #endif

   // By default in debug builds we turn on nested interrupt support so that
   // mmu_unmapped events cause the $error function to be called as quickly as possible.
   // This aids debugging of finding rogue pointers.
   #define NESTED_INTERRUPT_SUPPORT
#endif

// Turn on support for nested interrupts.
// Needed for correct interaction of IRQs with scheduler
#define NESTED_INTERRUPT_SUPPORT

#ifdef NESTED_INTERRUPT_SUPPORT
   .CONST $INTERRUPT_STORE_STATE_SIZE 48;
#else
   .CONST $INTERRUPT_STORE_STATE_SIZE 45;
#endif


// *****************************************************************************
// MODULE:
//    $interrupt.block_macro
//
// DESCRIPTION:
//    Block interrupts macro
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0
//
// *****************************************************************************
#define $block_interrupts_macro         \
   r0 = M[$interrupt.block_count];     \
   r0 = r0 + 1;                        \
   M[$interrupt.block_count] = r0;     \
   M[$INT_ENABLE] = Null;              \
   nop;                                \
   nop;                                \
   nop



// *****************************************************************************
// MODULE:
//    $interrupt.unblock_macro
//
// DESCRIPTION:
//    Unblock interrupts macro
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    r0, r1
//
// *****************************************************************************
#define $unblock_interrupts_macro          \
   r0 = M[$interrupt.block_count];        \
   if Z call $error;                      \
      r0 = r0 - 1;                        \
      r1 = 1;                             \
      M[$interrupt.block_count] = r0;     \
      if NZ r1 = 0;                       \
      M[$INT_ENABLE] = r1



#endif
