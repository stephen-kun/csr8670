/* 
    Library allowing user to add debug printfs to their code and be able to
    enable / disable them as required using a single switch.
*/

/*!
 @file print.h
 @brief Debug print functions.

  This library allows applications to contain debug printfs in their code and
  to able to enable / disable them as required using a single switch:

  #define DEBUG_PRINT_ENABLED

  PRINT and CPRINT take the same arguments as printf and cprintf.
*/

#ifdef PRINT
#undef PRINT
#endif
#ifdef CPRINT
#undef CPRINT
#endif

#ifdef DEBUG_PRINT_ENABLED
#include <stdio.h>
#define PRINT(x) printf x
#define CPRINT(x) cprintf x
#else
#define PRINT(x)
#define CPRINT(x)
#endif
