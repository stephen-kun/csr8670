// *****************************************************************************
// %%fullcopyright(2005)        http://www.csr.com
// %%version
//
// $Change: 1882869 $  $DateTime:
// *****************************************************************************


#include "peq.h"

#ifndef CBOPS_EQ_HEADER_INCLUDED
#define CBOPS_EQ_HEADER_INCLUDED

// PEQ Parameters

   .CONST   $cbops.eq.parameter.INPUT_GAIN_EXPONENT_PTR       0;
   .CONST   $cbops.eq.parameter.INPUT_GAIN_MANTISA_PTR        1;
   .CONST   $cbops.eq.parameter.NUM_STAGES_FIELD              2;
   .CONST   $cbops.eq.parameter.STAGES_SCALES                 3;

// PEQ Data Structure    

   .CONST   $cbops.eq.INPUT_START_INDEX_FIELD       0;
   .CONST   $cbops.eq.OUTPUT_START_INDEX_FIELD      1;
   .CONST   $cbops.eq.PEQ_START_FIELD               2;

// This increases the size 
#define CBOPS_EQ_FILTER_OBJECT_SIZE(x)  ($cbops.eq.PEQ_START_FIELD + PEQ_OBJECT_SIZE(x))
#endif // CBOPS_EQ_HEADER_INCLUDED


