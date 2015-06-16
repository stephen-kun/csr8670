// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//     IIR resample completion operator
//
// DESCRIPTION:
//    Due to the cbops architecture.  A fix is required if the downsample operator
//    is used in a chain with other operators.  This is due to the usage of the
//    variables $cbops.amount_to_use and $cbops.amount_written
//
//   ******* DOWNSAMPLE OPERATIOR *********
//    For proper operation the downsample operator must be the first operator in the chain.
//    The downsample operator may operate in-place provided the input is not a port
//
//    After the completion of all the "amount_to_use" functions r5 will equal the amount
//    of output to generate:
//       M[$cbops.amount_to_use]  = r5;        M[$cbops.amount_written] = r5;
//
//    As the main function of each operator in the chain is called the amount of data to generated
//    is passed to the operator in r10
//        r10 = M[$cbops.amount_to_use];
//
//    Finally, after the main functions of all operators have been called, the input & output buffers
//    are advanced.
//        r0 = M[$cbops.amount_to_use];    // read_ptr increment
//        r1 = M[$cbops.amount_written];   // write_ptr increment
//
//    Recomended Configurations:
//        Input is a port output is a cbuffer
//            Downsample operators transfers from port to cbuffer and all other operators process the cbuffer
//        Input is a cbuffer and output is a port (or cbuffer)
//            Downsample operators processing in-place on cbuffer along with all operators but the last.  The
//            last operator (before this one) transfers from cbuffer to port.
//        Input and Output are both ports
//            No other operator may be in the chain.
//
//   ******* UPSAMPLE OPERATIOR *********
//    If the upsample operator is first in the chain, the completion operator is required.
//    Otherwise, the upsample operator should be the last in the chain.
//
//    The upsample operator may NOT process in-place.
//
//    After the completion of all the "amount_to_use" functions r5 will equal the amount
//    of input to process:
//       M[$cbops.amount_to_use]  = r5;        M[$cbops.amount_written] = r5;
//
//    As the main function of each operator in the chain is called the amount of data to process
//    is passed to the operator in r10
//        r10 = M[$cbops.amount_to_use];
//
//    Finally, after the main functions of all operators have been called, the input & output buffers
//    are advanced.
//        r0 = M[$cbops.amount_to_use];    // read_ptr increment
//        r1 = M[$cbops.amount_written];   // write_ptr increment
//
//    Recomended Configurations:
//        Input is a port output is a cbuffer
//            upsample operator transfers from port to cbuffer and all other operators process the cbuffer
//            The completion operator is required to correctly set M[$cbops.amount_to_use]
//        Input is a cbuffer and output is a port (or cbuffer)
//            All other operators process in-place on the cbuffer the upsample operator is last and
//            transfers from cbuffer to port.
//        Input and Output are both ports
//            No other operator may be in the chain.  The completion operator is not required
// *****************************************************************************


#include "cbops.h"

.MODULE $M.cbops.iir_resample_complete;
   .DATASEGMENT DM;

   .VAR  amount_to_use;
   // ** function vector **
   .VAR $cbops.iir_resample_complete[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,         // reset function
      $cbops.function_vector.NO_FUNCTION,         // amount to use function
      &$cbops.iir_resample_complete.main;         // main function

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbops.iir_resample_complete.main
//
// DESCRIPTION:
//    operator main function to complete downsampling.
//    This operator is the last in the chain.  Reseting $cbops.amount_to_use
//    to correctly advance the input buffer
//
// INPUTS:
//    - r6  = pointer to the list of input and output buffer pointers
//    - r7  = pointer to the list of buffer lengths
//    - r8  = pointer to operator structure
//    - r10 = the number of samples to generate
//
// OUTPUTS:
//    - r8  = pointer to operator structure
//
// TRASHED REGISTERS:
//    everything
//
// *****************************************************************************
.MODULE $M.cbops.iir_resample_complete.main;
   .CODESEGMENT CBOPS_IIR_RESAMPLE_COMPLETE_MAIN_PM;

$cbops.iir_resample_complete.main:
    // If Last operator in chain then set $cbops.amount_to_use to advance input buffer
    r4 = M[$M.cbops.iir_resample_complete.amount_to_use];
    M[$cbops.amount_to_use] = r4;
    rts;

.ENDMODULE;





