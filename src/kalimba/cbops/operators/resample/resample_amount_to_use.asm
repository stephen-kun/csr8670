// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************



#include "stack.h"


// *****************************************************************************
// MODULE:
//    $cbops.resample.upsample_amount_to_use
//
// DESCRIPTION:
//    Operator that copies the input sample to the output
//
// INPUTS:
//    - r6 = minimum available input amount
//    - r7 = minimum available output amount
//
// OUTPUTS:
//    - r5 = amount of input data to use
//
// TRASHED REGISTERS:
//    r0, r1, r5
//
// *****************************************************************************


.MODULE $M.cbops.resample.upsample_amount_to_use;
   .CODESEGMENT CBOPS_RESAMPLE_UPSAMPLE_AMOUNT_TO_USE_PM;

   $cbops.resample.upsample_amount_to_use:
   $push_rLink_macro;


   r0 = M[r8 + $cbops.resample.CONVERT_RATIO_FRAC_FIELD];
   // times the ratio to the output buffer space,
   // to work out how many input samples it can handle

   r1 = r0 * r7 (frac);
   r1 = r1 - 1;

   // prevent the number of samples being negative
   if NEG r1 = 0;

   r5 = r6;
   Null = r5 - r1;
   if GT r5 = r1;

   //** function ends
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $cbops.resample.downsample_amount_to_use
//
// DESCRIPTION:
//    Operator that copies the input sample to the output
//
// INPUTS:
//    - r6 = minimum available input amount
//    - r7 = minimum available output amount
//
// OUTPUTS:
//    - r5 = amount of input data to use
//
// TRASHED REGISTERS:
//    r0, r1, r5
//
// *****************************************************************************


.MODULE $M.cbops.resample.downsample_amount_to_use;
   .CODESEGMENT CBOPS_RESAMPLE_DOWNSAMPLE_AMOUNT_TO_USE_PM;

   $cbops.resample.downsample_amount_to_use:
   $push_rLink_macro;


   // r0 contains the invert of downsample ratio,
   // therefore r0 should be a pure fraction here
   r0 = M[r8 + $cbops.resample.INV_CONVERT_RATIO_FIELD];

   // times the ratio to the input buffer space,
   // to work out how many input samples it can handle ###
   r1 = r0 * r6 (frac);
   // minuse 3 here for a safe margin, prevent over-reading ###
   r1 = r1 - 3;

   // prevent the number of samples being negative
   if NEG r1 = 0;

   r5 = r7;

   Null = r5 - r1;
   if GT r5 = r1;

   //** function ends
   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;

