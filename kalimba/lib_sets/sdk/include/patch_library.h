// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef PATCH_LIBRARY_H_INCLUDED
#define PATCH_LIBRARY_H_INCLUDED

#include "patch.h"

// --------------------------Example Macros for patching ROM code
// define rom patch macros
// Fast ROM patch
// reg is the register that can be trashed
#define FAST_SW_ROM_PATCH_POINT(patch_id, reg, table_fast)  \
   reg = M[table_fast + patch_id];                          \
   if NZ jump reg;                                          \
   patch_id##.##PATCH_LABEL:



// Slow ROM patch
#define PUSH_R0_SLOW_SW_ROM_PATCH_POINT(patch_id, reg, table_slow, num_fast_patch)  \
   push r0;                                                                         \
   r0 = patch_id;                                                                   \
   reg = M[table_slow + ((patch_id - num_fast_patch) /16)];                         \
   Null = reg AND (1 << ((patch_id - num_fast_patch) & 0xF));                       \
   if NZ jump $patch.id_search;                                                     \
   patch_id##.##PATCH_LABEL:                                                        \
   pop r0;


// Slow ROM patch (Library version)
#define LIBS_PUSH_R0_SLOW_SW_ROM_PATCH_POINT(patch_id, reg) \
   push r0;                                                 \
   r0 = patch_id;                                           \
   reg = M[GETLOC(patch_id)];                               \
   Null = reg AND GETMASK(patch_id);                        \
   if NZ jump $patch.id_search;                             \
   patch_id##.##PATCH_LABEL:                                \
   pop r0;

// Slow ROM patch
// reg is the register that can be trashed - also trashes r0
#define SLOW_SW_ROM_PATCH_POINT(patch_id, reg, table_slow, num_fast_patch)    \
   r0 = patch_id;                                                             \
   reg = M[table_slow + ((patch_id - num_fast_patch) /16)];                   \
   Null = reg AND (1 << ((patch_id - num_fast_patch) & 0xF));                 \
   if NZ jump $patch.id_search;                                               \
   patch_id##.##PATCH_LABEL:


// Slow ROM patch (Library version)
#define LIBS_SLOW_SW_ROM_PATCH_POINT(patch_id, reg)   \
   r0 = patch_id;                                     \
   reg = M[GETLOC(patch_id)];                         \
   Null = reg AND GETMASK(patch_id);                  \
   if NZ jump $patch.id_search;                       \
   patch_id##.##PATCH_LABEL:

// Slow ROM patch
#define PUSH_REGS_SLOW_SW_ROM_PATCH_POINT(patch_id, table_slow, num_fast_patch) \
   pushm <r0,r1>;                                                               \
   r0 = patch_id;                                                               \
   r1 = M[table_slow + ((patch_id - num_fast_patch) /16)];                      \
   Null = r1 AND (1 << ((patch_id - num_fast_patch) & 0xF));                    \
   if NZ jump $patch.id_search;                                                 \
   patch_id##.##PATCH_LABEL:                                                    \
   popm <r0,r1>;

// Slow ROM patch (Library version)
#define LIBS_PUSH_REGS_SLOW_SW_ROM_PATCH_POINT(patch_id)    \
   pushm <r0,r1>;                                           \
   r0 = patch_id;                                           \
   r1 = M[GETLOC(patch_id)];                                \
   Null = r1 AND GETMASK(patch_id);                         \
   if NZ jump $patch.id_search;                             \
   patch_id##.##PATCH_LABEL:                                \
   popm <r0,r1>;



// Very Slow ROM patch
// NOTE: VERY_SLOW_SW_ROM_PATCH_POINT should be used only when rLink has been pushed
#define PUSH_R0_VERY_SLOW_SW_ROM_PATCH_POINT(patch_id) \
   push r0;                                    \
   r0 = patch_id;                              \
   call $patch.id_search;                \
   pop r0;


// Very Slow ROM patch
// trashes r0
// NOTE: VERY_SLOW_SW_ROM_PATCH_POINT should be used only when rLink has been pushed
#define VERY_SLOW_SW_ROM_PATCH_POINT(patch_id) \
   r0 = patch_id;                              \
   call $patch.id_search;                \

#define GETLOC(x) x ## _LOC
#define GETMASK(x) x ## _MASK

#endif // PATCH_LIBRARY_H_INCLUDED