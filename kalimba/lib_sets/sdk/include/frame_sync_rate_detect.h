// rate_detect data object definitions
.CONST $rate_detect.COUNTER                                0;  // initialize to zero
.CONST $rate_detect.COUNTER_THRESHOLD                      1;  // Compute warp after this many iterations
.CONST $rate_detect.EXPECTED_NUM_SAMPLES                   2;  // Number of samples expected after NUM_COUNTS_TO_ACCUM_INPUT
.CONST $rate_detect.CURRENT_ALPHA_INDEX                    3;  // initialize to 0
.CONST $rate_detect.ALPHA_LIMIT                            4;  // controls how much history is used in calculation
.CONST $rate_detect.AVERAGE_IO_RATIO                       5;  // Q.22, initialize to one (i.e. 2^22)
.CONST $rate_detect.TARGET_WARP_VALUE_OUTPUT_ENDPOINT      6;  // warp for $cbops.rate_adjustment_and_shift input data
.CONST $rate_detect.TARGET_WARP_VALUE_INPUT_ENDPOINT       7;  // warp for $cbops.rate_adjustment_and_shift output data
.CONST $rate_detect.NUM_SAMPLES                            8;  // number of input samples used in warp calculation
.CONST $rate_detect.INPUT_CBUFFER_STRUCTURE                9; // input cbuffer used to monitor rate
.CONST $rate_detect.LAST_WRITE_PTR_POS                     10; // used to track number of new input samples
.CONST $rate_detect.ACCUMULATOR                            11; // used to count number of samples collected over COUNTER_THRESHOLD iterations
.CONST $rate_detect.STALL_FIELD                            12; // initialize to non-zero
.CONST $rate_detect.WARP_MSG_COUNTER                       13; // nudge value 
.CONST $rate_detect.WARP_MSG_LIMIT                         14; // nudge value 

.CONST $rate_detect.STRUC_SIZE                             15;

.CONST $WARP_PARAMS_MESSAGE_ID                             0x1025;
