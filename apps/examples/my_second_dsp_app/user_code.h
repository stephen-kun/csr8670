#ifndef USER_CODE_HEADER_INCLUDED
#define USER_CODE_HEADER_INCLUDED

    // ** Function vector parameters **
    .CONST  $user_code.function_vector.RESET_FIELD                  0;
    .CONST  $user_code.function_vector.AMOUNT_TO_USE_FIELD          1;
    .CONST  $user_code.function_vector.MAIN_FIELD                   2;
    .CONST  $user_code.function_vector.STRUC_SIZE                   3;

    .CONST  $user_code.function_vector.NO_FUNCTION                  0;

    // FIR Filter operator structure definition

    .CONST  $user_code.fir_filter.INPUT_START_INDEX_FIELD           0;
    .CONST  $user_code.fir_filter.OUTPUT_START_INDEX_FIELD          1;
    .CONST  $user_code.fir_filter.COEFFICIENT_BUFFER_ADDR           2;
    .CONST  $user_code.fir_filter.HISTORY_BUFFER_ADDR               3;
    .CONST  $user_code.fir_filter.FILTER_LENGTH                     4;
    .CONST  $user_code.fir_filter.SHIFT_AMOUNT                      5;
    .CONST  $user_code.fir_filter.STRUC_SIZE                        6;

     // Defines for FIR filter
    #define $FILTER_LENGTH                                          111

#endif // USER_CODE_HEADER_INCLUDED
