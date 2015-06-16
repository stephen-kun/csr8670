// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


#ifndef PROFILER_HEADER_INCLUDED
#define PROFILER_HEADER_INCLUDED

   #define DETAILED_PROFILER_ON

   // r0 - r2 are explicitly saved and restored on the stack, since some profiler usages require this.
   #if defined(ENABLE_PROFILER_MACROS)
      #define PROFILER_START(addr)    \
         push r0;                      \
         push r1;                      \
         r0 = addr;                    \
         call $profiler.start;         \
         pop r1;                       \
         pop r0;

      #define PROFILER_STOP(addr)     \
         push r0;                      \
         push r1;                      \
         push r2;                      \
         r0 = addr;                    \
         call $profiler.stop;          \
         pop r2;                       \
         pop r1;                       \
         pop r0;

   #else
      #define PROFILER_START(addr)
      #define PROFILER_STOP(addr)
   #endif

   // set the maximum possible number of handlers - this is only used to detect
   // corruption in the linked list, and so can be quite large
   .CONST   $profiler.MAX_PROFILER_HANDLERS   50;

   .CONST   $profiler.LAST_ENTRY              -1;

   // by initialising profiler structures to the value of $profiler.UNINITIALISED
   // it will indicate to $profiler.start that the stucture needs registering
   // and so it will automatically call $profiler.register the frst time that
   // it is used.
   .CONST   $profiler.UNINITIALISED           -2;

   .CONST   $profiler.NEXT_ADDR_FIELD          0;
   .CONST   $profiler.CPU_FRACTION_FIELD       1;
   .CONST   $profiler.START_TIME_FIELD         2;
   .CONST   $profiler.INT_START_TIME_FIELD     3;
   .CONST   $profiler.TOTAL_TIME_FIELD         4;
   #ifdef DETAILED_PROFILER_ON
      .CONST   $profiler.RUN_CLKS_MS_START_FIELD    5;
      .CONST   $profiler.RUN_CLKS_LS_START_FIELD    6;
      .CONST   $profiler.RUN_CLKS_MS_TOTAL_FIELD    7;
      .CONST   $profiler.RUN_CLKS_LS_TOTAL_FIELD    8;
      .CONST   $profiler.RUN_CLKS_AVERAGE_FIELD     9;
      .CONST   $profiler.RUN_CLKS_MS_MAX_FIELD     10;
      .CONST   $profiler.RUN_CLKS_LS_MAX_FIELD     11;
      .CONST   $profiler.INT_START_CLKS_MS_FIELD   12;
      .CONST   $profiler.INT_START_CLKS_LS_FIELD   13;
      .CONST   $profiler.INSTRS_MS_START_FIELD     14;
      .CONST   $profiler.INSTRS_LS_START_FIELD     15;
      .CONST   $profiler.INSTRS_MS_TOTAL_FIELD     16;
      .CONST   $profiler.INSTRS_LS_TOTAL_FIELD     17;
      .CONST   $profiler.INSTRS_AVERAGE_FIELD      18;
      .CONST   $profiler.INSTRS_MS_MAX_FIELD       19;
      .CONST   $profiler.INSTRS_LS_MAX_FIELD       20;
      .CONST   $profiler.INT_START_INSTRS_MS_FIELD 21;
      .CONST   $profiler.INT_START_INSTRS_LS_FIELD 22;
      .CONST   $profiler.STALLS_MS_START_FIELD     23;
      .CONST   $profiler.STALLS_LS_START_FIELD     24;
      .CONST   $profiler.STALLS_MS_TOTAL_FIELD     25;
      .CONST   $profiler.STALLS_LS_TOTAL_FIELD     26;
      .CONST   $profiler.STALLS_AVERAGE_FIELD      27;
      .CONST   $profiler.STALLS_MS_MAX_FIELD       28;
      .CONST   $profiler.STALLS_LS_MAX_FIELD       29;
      .CONST   $profiler.INT_START_STALLS_MS_FIELD 30;
      .CONST   $profiler.INT_START_STALLS_LS_FIELD 31;
      .CONST   $profiler.TEMP_COUNT_FIELD          32;
      .CONST   $profiler.COUNT_FIELD               33;
      .CONST   $profiler.STRUC_SIZE                34;
   #else
      .CONST   $profiler.STRUC_SIZE                5;
   #endif



// *****************************************************************************
// MODULE:
//    CODE_COVERAGE_DEF(x)
//
// DESCRIPTION:
//    Macro to create a code coverage variable.
//    Insert this macro in the variable region of a module that includes test points
//
// INPUTS:
//    - x = Number of entry points in module
//
// OUTPUTS:
//    -
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//       Do not terminate macro with a ';' semi-colon
// *****************************************************************************

// *****************************************************************************
// MODULE:
//    CODE_COVERAGE_ENTRY(x)
//
// DESCRIPTION:
//    Macro to increment a code coverage variable
//    Insert this macro into code where you want to test cverage
//
// INPUTS:
//    - x = Index (Zero-Based) of code coverage variable in module
//
// OUTPUTS:
//    -
//
// TRASHED REGISTERS:
//    none
//
// NOTES:
//       Do not terminate macro with a ';' semi-colon
//       These macros are used in conjunction with the Matlab utility functions
//       kalcoverage_reset and kalcoverage which zero all coverage variables
//       and read all coverage variables respectively
// *****************************************************************************
#ifdef DEBUG_ON
   #define CODE_COVERAGE_DEF(x)    \
      .VAR CODE_COVERAGE[x] = 0

   #define CODE_COVERAGE_ENTRY(x)  \
      $push_r0_macro;               \
      r0 = M[CODE_COVERAGE + x];    \
      r0 = r0 + 1;                  \
      M[CODE_COVERAGE + x] = r0;    \
      $pop_r0_macro

#else // DEBUG_ON

   #define CODE_COVERAGE_DEF(x)
   #define CODE_COVERAGE_ENTRY(x)

#endif // DEBUG_ON


#endif // PROFILER_HEADER_INCLUDED
