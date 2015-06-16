// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Cbops operators Library
//
// DESCRIPTION:
//    This library provides routines to copy data between buffers/ports
//    while doing some form of processing.  The processing is defined with
//    operator functions which are held in a linked list.  Hence it is possible
//    to choose which functions are used and easily add other custom functions
//    as needed.
//
//    The routing of the audio through the operators is determined by the buffer
//    indexes set for the inputs and outputs of each operator.  The framework
//    provides each operator with a list of the input and output buffer pointers
//    with their associated buffer lengths.  The buffer indexes refer to the
//    locations within the lists for the buffer addresses and sizes.
//
//    For example, an operator that processes one channel of audio would have a
//    structure as shown below:
//
//       .VAR $mono_copy_process_struc[] =
//       &$mono_copy_op,         // First operator block
//       1,                      // Number of inputs
//       &$input_cbuffer_struc,  // Address of input cbuffer
//       1,                      // Number of outputs
//       &$output_cbuffer_struc; // Address of output cbuffer
//
//    An example operator descriptor for this process could be as shown below,
//    which uses the straight forward copy operator:
//
//       .BLOCK $mono_copy_op;
//          .VAR $mono_copy_op.next = $cbops.NO_MORE_OPERATORS;
//          .VAR $mono_copy_op.func = &$cbops.copy_op;
//          .VAR $mono_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
//                   0,   // Input index
//                   1;   // Output index
//       .ENDBLOCK;
//
// *****************************************************************************

#ifdef DEBUG_ON
   #define ENABLE_PROFILER_MACROS
   #define CBOPS_DEBUG
#endif

#include "stack.h"
#include "profiler.h"
#include "cbuffer.h"
#include "cbops.h"


.MODULE $cbops;
   .DATASEGMENT DM;

   .VAR struc_ptr;
   .VAR amount_to_use;
   .VAR amount_written;

   // arrays of addresses and sizes for the input and output buffers
   .VAR buffer_sizes[$cbops.MAX_NUM_CHANNELS];
   .VAR buffer_addresses[$cbops.MAX_NUM_CHANNELS];
   .VAR buffer_pointers[$cbops.MAX_NUM_CHANNELS];
   
   #ifdef BASE_REGISTER_MODE
      .VAR buffer_start_addresses[$cbops.MAX_NUM_CHANNELS];
   #endif

.ENDMODULE;



// *****************************************************************************
// MODULE:
//    $cbops.copy
//
// DESCRIPTION:
//    Copy available data from the input cbuffer/port to output cbuffer/port.
//    The copying is done by calling a list of operator routines which are held
//    in a linked list.
//
// INPUTS:
//    - r8 = pointer to cbop copy structure:
//       - Pointer to the first cbop descriptor structure in the operator list
//       - Number of input buffers
//       - ... list of the input buffers
//       - Number of output buffers
//       - ... list of the output buffers
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    assume everything except r8
//
// NOTES:
//    Interrupts must be blocked during this call.
//
// *****************************************************************************
.MODULE $M.cbops.copy;
   .CODESEGMENT CBOPS_COPY_PM;
   .DATASEGMENT DM;

#ifdef CBOPS_DEBUG
   .VAR count;
#endif


   $cbops.copy:

   // push rLink onto stack
   $push_rLink_macro;

   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $cbops.profile_copy[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      r0 = &$cbops.profile_copy;
      call $profiler.start;
   #endif

   // set a modify register for incrementing through the buffers
   M1 = 1;

   // ** calc amount of data in input buffers **
   // load the pointer to the buffers
   I0 = r8 + $cbops.NUM_INPUTS_FIELD;

   // set r6 to a large value (so minimum function below works)
   r6 = 0x7FFF;

   // set r7 to a large value (as above)
   // and read the number of inputs into r0
   r7 = r6, r0 = M[I0,M1];

   // load the number of inputs in r10
   // and get the first buffer structure into r0
   r10 = r0, r0 = M[I0,M1];
#ifdef CBOPS_DEBUG
   r9 = r10; 
#endif 
   // load the address of the array to store the portid/cbuf struc pointers
   I1 = &$cbops.buffer_pointers;

   // store struc pointer for later
   M[$cbops.struc_ptr] = r8;

   // work through the input buffers
   do min_amount_data_loop;
      // store portid/cbuffer struc ptr into the buffer pointer table
      M[I1,M1] = r0;
      call $cbuffer.calc_amount_data;
      Null = r0 - r6;
      // r6 = min(current_amount_in, new_amount_in)
      // and load the next input structure
      if NEG r6 = r0, r0 = M[I0,M1];
   min_amount_data_loop:

   // ** calc amount of space in output buffers **
   // the last read above read the number of outputs
   // read the first output buffer structure
   r10 = r0, r0 = M[I0,M1];
#ifdef CBOPS_DEBUG
   r9 = r9 + r10;
   Null = $cbops.MAX_NUM_CHANNELS - r9;                   
   if NEG call $error;
#endif

   // work through the buffers
   do min_amount_space_loop;
      // store portid/cbuffer struc ptr into the buffer pointer table
      M[I1,M1] = r0;
      call $cbuffer.calc_amount_space;
      Null = r0 - r7;
      // r7 = min(current_amount_out, new_amount_out)
      // and load the next output structure
      if NEG r7 = r0, r0 = M[I0,M1];
   min_amount_space_loop:

   // set r5 to min(amount_out, amount_in)
   r5 = r6;
   Null = r5 - r7;
   if POS r5 = r7;

   // ** calc amount of data to use **
   // get the operator structure address
   r8 = M[r8 + $cbops.OPERATOR_STRUC_ADDR_FIELD];

   #ifdef CBOPS_DEBUG
      r1 = $cbops.MAX_OPERATORS;
      M[count] = r1;
   #endif


   // ** operators must preserve r8 **
   amount_to_use_loop:

      #ifdef CBOPS_DEBUG
         // check we haven't looped more times than $cbops.MAX_OPERATORS
         r1 = M[count];
         r1 = r1 - 1;
         M[count] = r1;
         // linked list corrupt or num_operators>MAX_OPERATORS
         if NEG call $error;
      #endif

      // load the function address of the "amount of data to use" function
      r0 = M[r8 + $cbops.FUNCTION_VECTOR_FIELD];
      // load the parameter area for the operator
      r8 = r8 + $cbops.PARAMETER_AREA_START_FIELD;
      r0 = M[r0 + $cbops.function_vector.AMOUNT_TO_USE_FIELD];
      // if it isn't zero then call it
      if NZ call r0;

      // load the next operator structure
      r8 = M[r8 + ($cbops.NEXT_OPERATOR_ADDR_FIELD - $cbops.PARAMETER_AREA_START_FIELD)];
      // if there are no more operators we are done
      Null = r8 - $cbops.NO_MORE_OPERATORS;

   if NZ jump amount_to_use_loop;

   // r5 now holds the amount of input data that we need to copy

   // limit the maximum number of words that we copy in one go, this is to make
   // sure that we don't lock out other interrupts for too long
   r0 = r5 - $cbops.MAX_COPY_SIZE;
   if POS r5 = r5 - r0;

   // restore struc pointer
   r8 = M[$cbops.struc_ptr];

   // store in_data_amount_to_use
   M[$cbops.amount_to_use] = r5;
   // if nothing available to copy just exit
   if Z jump done;

   // store out_data_amount_to_use
   M[$cbops.amount_written] = r5;

   // ** get the read addresses and sizes of the input buffers **
   I0 = r8 + $cbops.NUM_INPUTS_FIELD;

   // load the address of the array to store the input and output addresses
   I4 = &$cbops.buffer_addresses;
   // load the address of the array to store the input and output sizes
   I1 = &$cbops.buffer_sizes;

   #ifdef BASE_REGISTER_MODE
      I2 = &$cbops.buffer_start_addresses;
   #endif

   // get the number of inputs
   r0 = M[I0,1];

   // load r10 with the number of inputs
   // and load the first input buffer structure into r0
   r10 = r0, r0 = M[I0,M1];

   do get_read_address_and_size_loop;
      #ifdef BASE_REGISTER_MODE
         call $cbuffer.get_read_address_and_size_and_start_address;
         M[I2,1] = r2;
      #else
         call $cbuffer.get_read_address_and_size;
      #endif
      // store the read address
      // and load the next buffer to check
      M[I4,1] = r0, r0 = M[I0,1];

      // store the buffer size
      M[I1,1] = r1;
   get_read_address_and_size_loop:


   // ** get the write addresses and sizes of the output buffers **
   // last read above got the number of outputs
   // and load the first output buffer structure
   r10 = r0, r0 = M[I0,M1];

   do get_write_address_and_size_loop;
      #ifdef BASE_REGISTER_MODE
         call $cbuffer.get_write_address_and_size_and_start_address;
         M[I2,1] = r2;
      #else
         call $cbuffer.get_write_address_and_size;
      #endif
      // store the write address
      // and load the next buffer to check
      M[I4,1] = r0, r0 = M[I0,1];

      // store the buffer size
      M[I1,M1] = r1;
   get_write_address_and_size_loop:

   // get the structure address to get address of the first structure
   r8 = M[r8 + $cbops.OPERATOR_STRUC_ADDR_FIELD];

   #ifdef CBOPS_DEBUG
      r1 = $cbops.MAX_OPERATORS;
      M[count] = r1;
   #endif // CBOPS_DEBUG

   // ** operators must preserve r8 **
   operator_functions_loop:
      #ifdef CBOPS_DEBUG
         // check we haven't looped more times than $cbops.MAX_OPERATORS
         r1 = M[count];
         r1 = r1 - 1;
         M[count] = r1;
         // linked list corrupt or num_operators>MAX_OPERATORS
         if NEG call $error;
      #endif // CBOPS_DEBUG

      // load these here rather than in every operator
      #ifdef BASE_REGISTER_MODE
         r5 = &$cbops.buffer_start_addresses;
      #endif
      r6 = &$cbops.buffer_addresses;
      r7 = &$cbops.buffer_sizes;

      // load the loop counter with number of samples we have been asked to process
      r10 = M[$cbops.amount_to_use];
      // load the operator function vector
      r0 = M[r8 + $cbops.FUNCTION_VECTOR_FIELD];
      // put the address of the parameter area in r8
      r8 = r8 + $cbops.PARAMETER_AREA_START_FIELD;
      // read in the function address
      r0 = M[r0 + $cbops.function_vector.MAIN_FIELD];
      // call the main processing routine for the operator
      if NZ call r0;

      // load the next operator
      r8 = M[r8 + ($cbops.NEXT_OPERATOR_ADDR_FIELD - $cbops.PARAMETER_AREA_START_FIELD)];
      // if there are no more operators we are done
      Null = r8 - $cbops.NO_MORE_OPERATORS;
   if NZ jump operator_functions_loop;


   // ** update the input pointers **
   // restore struc pointer
   r8 = M[$cbops.struc_ptr];

   I1 = r8 + $cbops.NUM_INPUTS_FIELD;

   I2 = &$cbops.buffer_addresses;
   I3 = &$cbops.buffer_sizes;
   #ifdef BASE_REGISTER_MODE
      I4 = &$cbops.buffer_start_addresses;
   #endif

   // set up some modify registers
   M1 = 1;
   // read_ptr increment
   r0 = M[$cbops.amount_to_use];
   M2 = r0;
   // write_ptr increment
   r0 = M[$cbops.amount_written];
   // and read the number of inputs
   M3 = r0, r0 = M[I1,M1];

   // load r10 with the number of inputs
   // and get the first input buffer structure
   I7 = r0, r0 = M[I1,M1];

   update_input_pointers_loop:
      // load the current buffer size (if it is 1 then we 'know' it is a port)
      #ifdef BASE_REGISTER_MODE
         r2 = M[I3,1], r3 = M[I4,1];   // get size and start address
         push r3;
         pop B0;
      #else
         r2 = M[I3,1];                 // get size
      #endif
      // check if it is a port and get address
      Null = r2 - M1, r1 = M[I2,M1];
      if Z jump input_is_a_port;
         // set I0 to the buffer address
         I0 = r1;
         // set L0 to the buffer size
         L0 = r2;
         // dummy read to increment index register (it's a cbuffer)
         // M2 contains the number of samples that have been read from the input
         L0 = 0, r1 = M[I0,M2];
         r1 = I0;
      input_is_a_port:
      #ifdef BASE_REGISTER_MODE
         push Null;
         pop B0;
      #endif
      call $cbuffer.set_read_address;

      // get the next cbuffer structure
      r0 = M[I1,1];
      I7 = I7 - 1;
   if GT jump update_input_pointers_loop;

   // the last read above read the number of outputs, put in r10
   // and get the first output buffer structure
   I7 = r0, r0 = M[I1,M1];

   update_output_pointers_loop:
      // load the current buffer size (if it is 1 then we 'know' it is a port)
      #ifdef BASE_REGISTER_MODE
         r2 = M[I3,1], r3 = M[I4,1];   // get size and start address
         push r3;
         pop B0;
      #else
         r2 = M[I3,1];                 // get size
      #endif
      // check if it is a port and get address
      Null = r2 - M1, r1 = M[I2,M1];
      if Z jump output_is_a_port;
         // set I0 to the buffer address
         I0 = r1;
         // set L0 to the buffer size
         L0 = r2;
         // dummy read to increment index register (it's a cbuffer)
         // M3 contains the number of samples that have been written to the output
         L0 = 0, r1 = M[I0,M3];
         r1 = I0;
      output_is_a_port:
      #ifdef BASE_REGISTER_MODE
         push Null;
         pop B0;
      #endif      
      call $cbuffer.set_write_address;

      // get the next cbuffer structure
      r0 = M[I1,1];
      I7 = I7 - 1;
   if GT jump update_output_pointers_loop;

   done:

   // stop profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      r0 = &$cbops.profile_copy;
      call $profiler.stop;
   #endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;





// *****************************************************************************
// MODULE:
//    $cbops.reset
//
// DESCRIPTION:
//    Call the reset function, if there is one, for each operator in the linked
//    list.
//
// INPUTS:
//    - r8 = pointer to cbop copy structure:
//       - Pointer to the first cbop descriptor structure in the operator list
//       - Number of input buffers
//       - ... list of the input buffers
//       - Number of output buffers
//       - ... list of the output buffers
//
// OUTPUTS:
//    - none
//
// TRASHED REGISTERS:
//    everything
//
// NOTES:
//    Interrupts must be blocked during this call.
//
// *****************************************************************************
.MODULE $M.cbops.reset;
   .CODESEGMENT CBOPS_RESET_PM;
   .DATASEGMENT DM;

#ifdef CBOPS_DEBUG
   .VAR count;
#endif


   $cbops.reset:

   // push rLink onto stack
   $push_rLink_macro;

   // start profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      .VAR/DM1 $cbops.profile_reset[$profiler.STRUC_SIZE] = $profiler.UNINITIALISED, 0 ...;
      r0 = &$cbops.profile_reset;
      call $profiler.start;
   #endif

   // store struc pointer for later
   M[$cbops.struc_ptr] = r8;

   // ** calc amount of data to use **
   // get the operator structure address
   r8 = M[r8 + $cbops.OPERATOR_STRUC_ADDR_FIELD];

   #ifdef CBOPS_DEBUG
      r1 = $cbops.MAX_OPERATORS;
      M[count] = r1;
   #endif


   // ** operators must preserve r8 **
   reset_loop:

      #ifdef CBOPS_DEBUG
         // check we haven't looped more times than $cbops.MAX_OPERATORS
         r1 = M[count];
         r1 = r1 - 1;
         M[count] = r1;
         // linked list corrupt or num_operators>MAX_OPERATORS
         if NEG call $error;
      #endif

      // load the function address of the "reset" function
      r0 = M[r8 + $cbops.FUNCTION_VECTOR_FIELD];
      // load the parameter area for the operator
      r8 = r8 + $cbops.PARAMETER_AREA_START_FIELD;
      r0 = M[r0 + $cbops.function_vector.RESET_FIELD];
      // if it isn't zero then call it
      if NZ call r0;

      // load the next operator structure
      r8 = M[r8 + ($cbops.NEXT_OPERATOR_ADDR_FIELD - $cbops.PARAMETER_AREA_START_FIELD)];
      // if there are no more operators we are done
      Null = r8 - $cbops.NO_MORE_OPERATORS;

   if NZ jump reset_loop;


   // stop profiling if enabled
   #ifdef ENABLE_PROFILER_MACROS
      r0 = &$cbops.profile_copy;
      call $profiler.stop;
   #endif

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;






