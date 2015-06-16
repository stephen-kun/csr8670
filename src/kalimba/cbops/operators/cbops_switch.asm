// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1322655 $  $DateTime: 2012/06/07 14:16:10 $
// *****************************************************************************


// *****************************************************************************
// NAME:
//    Switch operator
//
// DESCRIPTION:
//    Basic operation:
//
//    The switch operator is a special purpose cbops operator that is designed
//    to be used within an existing cbops operator chain for the purpose of
//    enabling or disabling operator functions. The switch operator should be
//    inserted into the chain immediately before an existing operator
//    instance that is to be switched.
//
//    There are two key ways to use the switch operator:
//
//    1/ Disable/enable an operator:
//
//    In this mode the operator immediately following the switch operator in
//    a chain is disabled or enabled according to the value of a variable
//    pointed to by the $cbops.switch_op.SWITCH_ADDR_FIELD structure field.
//    Other operators in the chain are called and operate as normal.
//    The operator is processed if the value is 1 ($cbops.switch_op.ON)
//    and it is skipped if the value is 0 ($cbops.switch_op.OFF). See
//    below for extensions to the basic operation.
//
//    It should be noted that when an operator is disabled then no associated
//    copy operations will be performed. As such this mode is most useful for
//    in-place operations (i.e. input and output buffers are the same).
//
//    2/ Select an alternative chain:
//
//    In this mode a non zero $cbops.switch_op.ALT_NEXT_FIELD structure
//    field must be specified. In this situation the variable pointed to
//    by the $cbops.switch_op.SWITCH_ADDR_FIELD structure field is used
//    to select which chain of operators is processed. The original chain
//    is processed if the value is 1 ($cbops.switch_op.ON) and the alternate
//    chain is processed if the value is 0 ($cbops.switch_op.OFF).
//
//    Extensions:
//
//    a/ Bit field:
//
//    The switch operator has been extended to associate a specific bit in the
//    switch control variable for operator switching. This allows a single
//    variable to be used for multiple configuration options. A mask given in the
//    $cbops.switch_op.SWITCH_MASK_FIELD field with a single bit set is used for
//    this purpose. If this field is not used (and zero) then bit 0 will be
//    used by default.
//
//    b/ Control sense inversion:
//
//    A flag can also be set to invert the sense of the switch control.
//    Setting the $cbops.switch_op.INVERT_CONTROL_FIELD field to 1 will
//    invert the sense (zero is the default).
//
// *****************************************************************************
#include "cbops.h"
#include "stack.h"
#include "cbops_switch.h"

.MODULE $M.cbops.switch_op;
   .DATASEGMENT DM;

   // ** function vector **
   .VAR $cbops.switch_op[$cbops.function_vector.STRUC_SIZE] =
      $cbops.switch_op.reset,                      // Reset function
      $cbops.switch_op.amount_to_use,              // Amount to use function
      $cbops.switch_op.main;                       // Main function

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops.switch_op.reset
//
// DESCRIPTION:
//    Operator that allows another operator to be switched on or off
//
// INPUTS:
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to operator structure parameters
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - r8 = pointer to the "switched" operator instance structure parameters
//           (i.e. the operator next in the chain after the switch operator).
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3 and those used by the given operator function
//
// *****************************************************************************
.MODULE $M.cbops.switch_op.reset;
   .CODESEGMENT CBOPS_SWITCH_OP_RESET_PM;

   $cbops.switch_op.reset:

   r3 = $cbops.function_vector.RESET_FIELD;           //
   jump $cbops.switch_op.helper;                      //

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops.switch_op.amount_to_use
//
// DESCRIPTION:
//    Operator that allows another operator to be switched on or off
//
// INPUTS:
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to operator structure parameters
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - r8 = pointer to the "switched" operator instance structure parameters
//           (i.e. the operator next in the chain after the switch operator).
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3 and those used by the given operator function
//
// *****************************************************************************
.MODULE $M.cbops.switch_op.amount_to_use;
   .CODESEGMENT CBOPS_SWITCH_OP_AMOUNT_TO_USE_PM;

   $cbops.switch_op.amount_to_use:


   r3 = $cbops.function_vector.AMOUNT_TO_USE_FIELD;   //
   jump $cbops.switch_op.helper;                      //

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $cbops.switch_op.main
//
// DESCRIPTION:
//    Operator that allows another operator to be switched on or off
//
// INPUTS:
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to operator structure parameters
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - r8 = pointer to the "switched" operator instance structure parameters
//           (i.e. the operator next in the chain after the switch operator).
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3 and those used by the given operator function
//
// *****************************************************************************
.MODULE $M.cbops.switch_op.main;
   .CODESEGMENT CBOPS_SWITCH_OP_MAIN_PM;

   $cbops.switch_op.main:

   r3 = $cbops.function_vector.MAIN_FIELD;            //
   jump $cbops.switch_op.helper;                      //

.ENDMODULE;

// *****************************************************************************
// MODULE:
//    $cbops.switch_op.helper
//
// DESCRIPTION:
//    Helper that provides functionality to switch cbops operator chains
//
// INPUTS:
//    - r3 = function vector (e.g. $cbops.function_vector.RESET_FIELD etc)
//    - r6 = pointer to the list of input and output buffer pointers
//    - r7 = pointer to the list of buffer lengths
//    - r8 = pointer to operator structure parameters
//    - r10 = the number of samples to process
//
// OUTPUTS:
//    - r8 = pointer to the "switched" operator instance structure parameters
//           (i.e. the operator next in the chain after the switch operator).
//
// TRASHED REGISTERS:
//    r0, r1, r2 and those used by the given operator function
//
// *****************************************************************************
.MODULE $M.cbops.switch_op.helper;
   .CODESEGMENT CBOPS_SWITCH_OP_HELPER_PM;

   $cbops.switch_op.helper:

   // Get the mask and apply, default mask to 1
   r2 = 1;                                               // Default switch bit field
   r0 = M[r8 + $cbops.switch_op.SWITCH_ADDR_FIELD];      // Pointer to the operator switch
   r1 = M[r8 + $cbops.switch_op.SWITCH_MASK_FIELD];      // Operator switch mask (one bit should be set)
   if Z r1 = r2;                                         // If no mask then assume bit 0

   // Get the control address and invert flag (- if zero XOR does nothing else inverts all control bits)
   r0 = M[r0];                                           // Get switch status
   r2 = M[r8 + $cbops.switch_op.INVERT_CONTROL_FIELD];   // Flag used to invert the sense of the switch control
   if NZ r0 = r0 XOR r1;                                 // Invert

   // If the switch is set always use the next operator
   r0 = r0 AND r1;                                       // Select the bit used for the switch control
   if NZ jump exit;                                      //

   // Alternate or bypass mode
   r0 = M[r8 + $cbops.switch_op.ALT_NEXT_FIELD];         //
   if Z jump bypass;                                     //

      // Use alternate mode
      r8 = r8 - ($cbops.NEXT_OPERATOR_ADDR_FIELD - $cbops.PARAMETER_AREA_START_FIELD - $cbops.switch_op.ALT_NEXT_FIELD);
      jump exit;                                         // All done

   bypass:
      // Use bypass mode - skip the next operator (if it exists)

      // Get the switch next pointer
      r0 = M[r8 + ($cbops.NEXT_OPERATOR_ADDR_FIELD - $cbops.PARAMETER_AREA_START_FIELD)];

      null = r0 - $cbops.NO_MORE_OPERATORS;              // Check for no more operators
      if Z jump exit;                                    // If no more operators r8 = pointer to switch operator parameter struc
         r8 = r0 + $cbops.PARAMETER_AREA_START_FIELD;    // ...otherwise point at the next operator parameter struc
         // fallthrough

   exit:

   rts;
.ENDMODULE;

