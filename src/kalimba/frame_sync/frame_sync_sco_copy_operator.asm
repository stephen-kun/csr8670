// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2007-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    SCO copy operator
//
// DESCRIPTION:
//    The CBOPS library copies the minimum of the amount of data in the input
// buffers and the amount of space in the output buffers. However, for the SCO
// the firmware provide rate matching based the amount of data in the port buffer.
// Furthermore, reading the amount of data in the port form the DSP is ambiguous
// due to re-transmission logic in the firmware.  The best we can do is transfer
// data to the port at a steady rate.
//
// The sco copy operator is only called during the amount to use
// calculation. It uses the shift copy operator for processing
// in the main processing loop.
//
//
// *****************************************************************************

#include "stack.h"

#include "frame_sync_sco_copy_operator.h"
#include "cbops_vector_table.h"
#include "architecture.h"
#include "cbuffer.h"


.MODULE $M.frame_sync.sco_copy_op;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $frame_sync.sco_copy_op[$cbops.function_vector.STRUC_SIZE] =
      $cbops.function_vector.NO_FUNCTION,    // reset function
      &$frame_sync.sco_copy_op.amount_to_use,// amount to use function
      &$cbops.shift.main;                    // main function

.ENDMODULE;



// *****************************************************************************
// MODULE:
//   $frame_sync.sco_copy_op.amount_to_use
//
// DESCRIPTION:
//    Operator to limit the amount of data copied in each call, NOTE it does not
// actually copy any data, it simply limits the amount of data other operators
// will copy.
//
//
// INPUTS:
//    - r5 = the minimum of the number of input samples available and the
//      amount of output space available
//    - r6 = the number of input samples available
//    - r7 = the amount of output space available
//    - r8 = pointer to operator structure
//
// OUTPUTS:
//    - r5 = the number of samples to process
//
// TRASHED REGISTERS:
//    r0
//
// *****************************************************************************
.MODULE $M.frame_sync.sco_copy_op.amount_to_use;
   .CODESEGMENT FRAME_SYNC_SCO_COPY_OP_AMOUNT_TO_USE_PM;
   .DATASEGMENT DM;

   // ** amount to use function **
$frame_sync.sco_copy_op.amount_to_use:
   // Limit r5
   r1 = M[r8 + ($cbops.shift.SHIFT_AMOUNT_FIELD + 1)];

   // SP.  Cludge for WBS
   NULL = M[r8 + $cbops.shift.SHIFT_AMOUNT_FIELD];
   if NZ jump wbs_done; 
      // Check data in port 
      r2 = r7 - 255; //(- data in port)
      NULL = r1 + r2;
      if NEG r5=NULL;
wbs_done:
   Null = r5 - r1;
   if POS r5 = r1;
   rts;

.ENDMODULE;
