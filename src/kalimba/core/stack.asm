// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Stack Library
//
// DESCRIPTION:
//    This library has functions and macros to provide a simple software
//    stack.
//
//    The Kalimba DSP has an rLink register that is used to hold a subroutine
//    return address.  When a subroutine call is performed by a CALL
//    instruction, rLink is set to the subroutine return address.  The
//    subroutine return is preformed by an RTS instruction, its effect is
//    equivalent to a JUMP to the value of the rLink register.
//
//    When a subroutine is nested within another, a method of saving and
//    restoring the value of the rLink register at the start and end of the
//    subroutine is required.  A software stack that allows pushing and
//    popping the rLink register is the most convienient way to achieve this.
//    This functionality is supported by the Stack library.  The r9 register
//    is reserved as the stack pointer.
//
//    Generally r9 should not be used by the programmer.  Sometimes there may
//    be a place where the programmer needs to use r9 other than as the stack
//    pointer, for example in a fast routine where the speed of execution is
//    much improved by making use of the extra register.  If this is the case
//    then the function $dont_use_r9_as_stack_ptr should be called at the
//    start of the block of code and $use_r9_as_stack_ptr at the end.  These
//    functions save and restore the value of r9 as required and also indicate
//    to the interrupt service routine whether r9 is being used as the stack
//    pointer or not.
//
//    The default size of the stack is 32 words, this may be changed by editing
//    the definition of $stack.SIZE and rebuilding the library
//
//    When developing applications it is useful to be able to catch stack
//    overflows or underflows to find bugs in a program.  By defining
//    DEBUG_STACK_OVERFLOW macro at the top of your application source code
//    extra code is inserted to detect stack over and underflows.
//
//
//    Planned use is as follows:
//    @verbatim
//    .MODULE $test;
//
//       // push rLink onto stack
//       $push_rLink_marco;
//
//       ...    // your code
//       ...
//
//       // pop rLink from stack
//       jump $pop_rLink_and_rts;
//
//    .ENDMODULE;
//    @endverbatim
//
// *****************************************************************************
#ifndef STACK_INCLUDED
#define STACK_INCLUDED

#define ENABLE_DEBUG_PERFORMANCE_COUNTERS

#ifdef DEBUG_ON
   #ifndef DEBUG_STACK_OVERFLOW
   #define DEBUG_STACK_OVERFLOW
   #endif
#endif

#include "stack.h"
#include "interrupt.h"

.MODULE $stack;
   .DATASEGMENT DM;

   // Provide a big stack
   #if defined(BUILD_WITH_BIG_STACK) && !defined(BUILD_WITH_C_SUPPORT)
      .CONST C_EXTRA_STACK 200;
   #else
      #if defined(BUILD_WITH_C_SUPPORT)
         .CONST C_EXTRA_STACK 2000;
      #else
         .CONST C_EXTRA_STACK 0;
      #endif
   #endif

   // set the stack depth
   #ifdef NESTED_INTERRUPT_SUPPORT
      .CONST   $stack.SIZE  96+$INTERRUPT_STORE_STATE_SIZE*2+C_EXTRA_STACK;
   #else
      .CONST   $stack.SIZE  96+$INTERRUPT_STORE_STATE_SIZE+C_EXTRA_STACK;
   #endif

   // stack buffer should not be allocated at address 0; so allocated in DM2
   .VAR/DM2     buffer[$stack.SIZE];

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $stack.initialise
//
// DESCRIPTION:
//    Initialise the software stack
//
// INPUTS:
//    - none
//
// OUTPUTS:
//    - r9 = the stack pointer
//
// TRASHED REGISTERS:
//    none
//
// *****************************************************************************
.MODULE $M.stack.initialise;
   .CODESEGMENT STACK_INITIALISE_PM;
   .DATASEGMENT DM;

   #ifdef DEBUG_ON
      .CONST MAGIC_KEY    0x445248;
      .VAR stack_initialised_magic_key = MAGIC_KEY;
   #endif

   $stack.initialise:
   $_stack_initialise:   // TODO: C stub

   #ifdef DEBUG_ON
      // The stack should only be initialised once - we check that it
      // hasn't been initialised before by confirming the magic key is set.
      r0 = M[stack_initialised_magic_key];
      Null = r0 - MAGIC_KEY;
      // If error is called here it will most probably be because of memory
      // corruption in the stack buffer or some rogue code jumping to address 0
      // or the like.
      if NZ call $error;
      M[stack_initialised_magic_key] = Null;
   #endif

   r9 = &$stack.buffer + $stack.SIZE - 1;
   M[$STACK_END_ADDR] = r9;
   r9 = &$stack.buffer;
   M[$STACK_START_ADDR] = r9;
   M[$STACK_POINTER] = r9;
   M[$FRAME_POINTER] = r9;
   #if defined(ENABLE_DEBUG_PERFORMANCE_COUNTERS)
      // enable the performance counters in debug mode
      r0 = 1;
      M[$DBG_COUNTERS_EN] = r0;
   #endif
   rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $stack.pop_rLink_and_rts
//
// DESCRIPTION:
//    Shared code to pop rLink from the stack and rts.
//    Important: Code must be called with a jump instruction rather than a call.
//
// INPUTS:
//    - r9 = the current stack pointer
//
// OUTPUTS:
//    - r9 = the updated stack pointer
//
// TRASHED REGISTERS:
//    none
//
// *****************************************************************************
.MODULE $M.pop_rLink_and_rts;
   .CODESEGMENT POP_RLINK_AND_RTS_PM;

   $pop_rLink_and_rts:
   $pop_rLink_and_rts_macro;
.ENDMODULE;





#endif
