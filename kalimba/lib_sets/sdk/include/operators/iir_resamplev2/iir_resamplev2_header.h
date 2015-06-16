// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef CBOPS_IIR_RESAMPLEV2_HEADER_INCLUDED
#define CBOPS_IIR_RESAMPLEV2_HEADER_INCLUDED

/* -------------------- cBops Operator --------------------------------------- */
   .CONST   $iir_resamplev2.INPUT_1_START_INDEX_FIELD              0;
   .CONST   $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD             1;
   // Filter Definition
   .CONST   $iir_resamplev2.FILTER_DEFINITION_PTR_FIELD            2;
   .CONST   $iir_resamplev2.INPUT_SCALE_FIELD                      3;
   .CONST   $iir_resamplev2.OUTPUT_SCALE_FIELD                     4;
   // Buffer between Stages
   .CONST   $iir_resamplev2.INTERMEDIATE_CBUF_PTR_FIELD            5;
   .CONST   $iir_resamplev2.INTERMEDIATE_CBUF_LEN_FIELD            6;
   // 1st Stage
   .CONST   $iir_resamplev2.PARTIAL1_FIELD                         7;
   .CONST   $iir_resamplev2.SAMPLE_COUNT1_FIELD                    8;
   .CONST   $iir_resamplev2.FIR_HISTORY_BUF1_PTR_FIELD             9;
   .CONST   $iir_resamplev2.IIR_HISTORY_BUF1_PTR_FIELD             10;
   // 2nd Stage
   .CONST   $iir_resamplev2.PARTIAL2_FIELD                         11;
   .CONST   $iir_resamplev2.SAMPLE_COUNT2_FIELD                    12;
   .CONST   $iir_resamplev2.FIR_HISTORY_BUF2_PTR_FIELD             13;
   .CONST   $iir_resamplev2.IIR_HISTORY_BUF2_PTR_FIELD             14;
   // Reset Flags (Set to NULL)
   .CONST   $iir_resamplev2.RESET_FLAG_FIELD                       15;
   .CONST   $iir_resamplev2.STRUC_SIZE                             16;


/* -------------------- Completion Operator ---------------------------------- */
   .CONST   $cbops.complete.iir_resamplev2.STRUC_SIZE                         1;


/* ------------------------ History Buffers ---------------------------------- */

   .CONST   $IIR_RESAMPLEV2_IIR_BUFFER_SIZE      19;
   .CONST   $IIR_RESAMPLEV2_FIR_BUFFER_SIZE      10;
   .CONST   $IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE      ($IIR_RESAMPLEV2_IIR_BUFFER_SIZE+$IIR_RESAMPLEV2_FIR_BUFFER_SIZE);
   .CONST   $iir_resamplev2.OBJECT_SIZE               $iir_resamplev2.STRUC_SIZE + 2*$IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE;

   .CONST   $iir_resamplev2.OBJECT_SIZE_SNGL_STAGE    $iir_resamplev2.STRUC_SIZE + $IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE;


   // Interface to old frame sync
   .CONST   $cbops.frame.resamplev2.INPUT_PTR_FIELD                       0;
   .CONST   $cbops.frame.resamplev2.INPUT_LENGTH_FIELD                    1;
   .CONST   $cbops.frame.resamplev2.OUTPUT_PTR_FIELD                      2;
   .CONST   $cbops.frame.resamplev2.OUTPUT_LENGTH_FIELD                   3;
   .CONST   $cbops.frame.resamplev2.NUM_SAMPLES_FIELD                     4;
      // Filter Definition
   .CONST   $cbops.frame.resamplev2.FILTER_DEFINITION_PTR_FIELD           5;
   .CONST   $cbops.frame.resamplev2.INPUT_SCALE_FIELD                     6;
   .CONST   $cbops.frame.resamplev2.OUTPUT_SCALE_FIELD                    7;
   // Buffer between Stages
   .CONST   $cbops.frame.resamplev2.INTERMEDIATE_CBUF_PTR_FIELD           8;
   .CONST   $cbops.frame.resamplev2.INTERMEDIATE_CBUF_LEN_FIELD           9;
   // 1st Stage
   .CONST   $cbops.frame.resamplev2.PARTIAL1_FIELD                        10;
   .CONST   $cbops.frame.resamplev2.SAMPLE_COUNT1_FIELD                   11;
   .CONST   $cbops.frame.resamplev2.FIR_HISTORY_BUF1_PTR_FIELD            12;
   .CONST   $cbops.frame.resamplev2.IIR_HISTORY_BUF1_PTR_FIELD            13;
   // 2nd Stage
   .CONST   $cbops.frame.resamplev2.PARTIAL2_FIELD                        14;
   .CONST   $cbops.frame.resamplev2.SAMPLE_COUNT2_FIELD                   15;
   .CONST   $cbops.frame.resamplev2.FIR_HISTORY_BUF2_PTR_FIELD            16;
   .CONST   $cbops.frame.resamplev2.IIR_HISTORY_BUF2_PTR_FIELD            17;
   // Reset Flags (Set to NULL)
   .CONST   $cbops.frame.resamplev2.RESET_FLAG_FIELD                      18;
   .CONST   $cbops.frame.resamplev2.STRUC_SIZE                            19;

   .CONST   $cbops.frame.resamplev2.OBJECT_SIZE               $cbops.frame.resamplev2.STRUC_SIZE + 2*$IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE;

   .CONST   $cbops.frame.resamplev2.OBJECT_SIZE_SNGL_STAGE    $cbops.frame.resamplev2.STRUC_SIZE + $IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE;


#endif // CBOPS_IIR_RESAMPLE_HEADER_INCLUDED

