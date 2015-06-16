.linefile 1 "send_proc.asm"
.linefile 1 "<command-line>"
.linefile 1 "send_proc.asm"
.linefile 32 "send_proc.asm"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stack.h" 1
.linefile 33 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/timer.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/timer.h"
   .CONST $timer.MAX_TIMER_HANDLERS 50;

   .CONST $timer.LAST_ENTRY -1;

   .CONST $timer.NEXT_ADDR_FIELD 0;
   .CONST $timer.TIME_FIELD 1;
   .CONST $timer.HANDLER_ADDR_FIELD 2;
   .CONST $timer.ID_FIELD 3;
   .CONST $timer.STRUC_SIZE 4;

   .CONST $timer.n_us_delay.SHORT_DELAY 10;
   .CONST $timer.n_us_delay.MEDIUM_DELAY 150;
.linefile 34 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_codec.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_codec.h"
.CONST $sco_pkt_handler.SCO_PORT_FIELD 0;
.CONST $sco_pkt_handler.SCO_PAYLOAD_FIELD 1;
.CONST $sco_pkt_handler.INPUT_PTR_FIELD 2;
.CONST $sco_pkt_handler.OUTPUT_PTR_FIELD 3;
.CONST $sco_pkt_handler.ENABLE_FIELD 4;
.CONST $sco_pkt_handler.CONFIG_FIELD 5;
.CONST $sco_pkt_handler.STAT_LIMIT_FIELD 6;
.CONST $sco_pkt_handler.PACKET_IN_LEN_FIELD 7;
.CONST $sco_pkt_handler.PACKET_OUT_LEN_FIELD 8;
.CONST $sco_pkt_handler.DECODER_PTR 9;
.CONST $sco_pkt_handler.PLC_PROCESS_PTR 10;
.CONST $sco_pkt_handler.PLC_RESET_PTR 11;
.CONST $sco_pkt_handler.BFI_FIELD 12;
.CONST $sco_pkt_handler.PACKET_LOSS_FIELD 13;
.CONST $sco_pkt_handler.INV_STAT_LIMIT_FIELD 14;
.CONST $sco_pkt_handler.PACKET_COUNT_FIELD 15;
.CONST $sco_pkt_handler.BAD_PACKET_COUNT_FIELD 16;
.CONST $sco_pkt_handler.PLC_DATA_PTR_FIELD 17;

.CONST $sco_pkt_handler.SCO_OUT_PORT_FIELD 18;
.CONST $sco_pkt_handler.SCO_OUT_SHIFT_FIELD 19;
.CONST $sco_pkt_handler.SCO_OUT_BUFFER_FIELD 20;
.CONST $sco_pkt_handler.SCO_OUT_PKTSIZE_FIELD 21;
.CONST $sco_pkt_handler.SCO_PARAM_TESCO_FIELD 22;
.CONST $sco_pkt_handler.SCO_PARAM_SLOT_LS_FIELD 23;
.CONST $sco_pkt_handler.SCO_NEW_PARAMS_FLAG 24;
.CONST $sco_pkt_handler.JITTER_PTR_FIELD 25;


.CONST $sco_pkt_handler.ENCODER_BUFFER_FIELD 26;
.CONST $sco_pkt_handler.ENCODER_INPUT_SIZE_FIELD 27;
.CONST $sco_pkt_handler.ENCODER_OUTPUT_SIZE_FIELD 28;
.CONST $sco_pkt_handler.ENCODER_SETUP_FUNC_FIELD 29;
.CONST $sco_pkt_handler.ENCODER_PROC_FUNC_FIELD 30;

.CONST $sco_pkt_handler.STRUC_SIZE 31;


.CONST $sco_decoder.VALIDATE_FUNC 0;
.CONST $sco_decoder.DECODE_FUNC 1;
.CONST $sco_decoder.RESET_FUNC 2;
.CONST $sco_decoder.DATA_PTR 3;
.CONST $sco_decoder.THRESHOLD 4;
.CONST $sco_decoder.STRUC_SIZE 5;
.linefile 35 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h"
   .CONST $cbops_multirate.BUFFER_TABLE_FIELD 0;
   .CONST $cbops_multirate.MAIN_FIRST_OPERATOR_FIELD 1;
   .CONST $cbops_multirate.MTU_FIRST_OPERATOR_FIELD 2;
   .CONST $cbops_multirate.NUM_INPUTS_FIELD 3;


   .CONST $cbops_multirate.BufferTable.BUFFER_FIELD 0;
   .CONST $cbops_multirate.BufferTable.POINTER_FIELD 1;
   .CONST $cbops_multirate.BufferTable.TRANSFER_FIELD 2;
   .CONST $cbops_multirate.BufferTable.ENTRY_SIZE 3;


   .CONST $cbops_multirate.MTU_NEXT_OPERATOR_FIELD 0;
   .CONST $cbops_multirate.MAIN_NEXT_OPERATOR_FIELD 1;
   .CONST $cbops_multirate.FUNCTION_VECTOR_FIELD 2;
   .CONST $cbops_multirate.PARAMETER_AREA_START_FIELD 3;
   .CONST $cbops_multirate.STRUC_SIZE 4;

   .CONST $cbops.NO_MORE_OPERATORS -1;


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_vector_table.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_vector_table.h"
   .CONST $cbops.function_vector.RESET_FIELD 0;
   .CONST $cbops.function_vector.AMOUNT_TO_USE_FIELD 1;
   .CONST $cbops.function_vector.MAIN_FIELD 2;
   .CONST $cbops.function_vector.STRUC_SIZE 3;

   .CONST $cbops.function_vector.NO_FUNCTION 0;
.linefile 36 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_copy_op.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_copy_op.h"
   .CONST $cbops.copy_op.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.copy_op.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.copy_op.STRUC_SIZE 2;
.linefile 39 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_shift.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_shift.h"
   .CONST $cbops.shift.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.shift.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.shift.SHIFT_AMOUNT_FIELD 2;
   .CONST $cbops.shift.STRUC_SIZE 3;
.linefile 40 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_dither_and_shift.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_dither_and_shift.h"
   .CONST $cbops.dither_and_shift.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.dither_and_shift.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.dither_and_shift.SHIFT_AMOUNT_FIELD 2;
   .CONST $cbops.dither_and_shift.DITHER_TYPE_FIELD 3;
   .CONST $cbops.dither_and_shift.DITHER_FILTER_HIST_FIELD 4;
   .CONST $cbops.dither_and_shift.ENABLE_COMPRESSOR_FIELD 5;
   .CONST $cbops.dither_and_shift.STRUC_SIZE 6;


   .CONST $cbops.dither_and_shift.DITHER_TYPE_NONE 0;
   .CONST $cbops.dither_and_shift.DITHER_TYPE_TRIANGULAR 1;
   .CONST $cbops.dither_and_shift.DITHER_TYPE_SHAPED 2;




      .CONST $cbops.dither_and_shift.FILTER_COEFF_SIZE 5;
.linefile 41 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_rate_adjustment_and_shift.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_rate_adjustment_and_shift.h"
   .CONST $cbops.rate_adjustment_and_shift.INPUT1_START_INDEX_FIELD 0;
   .CONST $cbops.rate_adjustment_and_shift.OUTPUT1_START_INDEX_FIELD 1;
   .CONST $cbops.rate_adjustment_and_shift.SHIFT_AMOUNT_FIELD 2;
   .CONST $cbops.rate_adjustment_and_shift.MASTER_OP_FIELD 3;
   .CONST $cbops.rate_adjustment_and_shift.FILTER_COEFFS_FIELD 4;
   .CONST $cbops.rate_adjustment_and_shift.HIST1_BUF_FIELD 5;
   .CONST $cbops.rate_adjustment_and_shift.HIST1_BUF_START_FIELD 6;
   .CONST $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD 7;
   .CONST $cbops.rate_adjustment_and_shift.ENABLE_COMPRESSOR_FIELD 8;
   .CONST $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD 9;
   .CONST $cbops.rate_adjustment_and_shift.RF 10;
   .CONST $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD 11;
   .CONST $cbops.rate_adjustment_and_shift.WORKING_STATE_FIELD 12;
   .CONST $cbops.rate_adjustment_and_shift.TEMP_VAR_FIELD 13;

   .CONST $cbops.rate_adjustment_and_shift.STRUC_SIZE 14;


   .CONST $cbops.rate_adjustment_and_shift.SRA_UPRATE 21;
.linefile 42 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_rate_adjustment_and_shift.h"
      .CONST $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE 12;






  .CONST $sra.MOVING_STEP (0.0015*(1.0/1000.0)/10.0);
.linefile 42 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_switch_op.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_switch_op.h"
   .CONST $cbops.switch_op.PTR_STATE_FIELD 0;
   .CONST $cbops.switch_op.MTU_NEXT_TRUE_FIELD 1;
   .CONST $cbops.switch_op.MTU_NEXT_FALSE_FIELD 2;
   .CONST $cbops.switch_op.MAIN_NEXT_TRUE_FIELD 3;
   .CONST $cbops.switch_op.MAIN_NEXT_FALSE_FIELD 4;
   .CONST $cbops.switch_op.STRUC_SIZE 5;

   .CONST $cbops.mux_1to2_op.PTR_STATE_FIELD 0;
   .CONST $cbops.mux_1to2_op.NEXT_TRUE_FIELD 1;
   .CONST $cbops.mux_1to2_op.NEXT_FALSE_FIELD 2;
   .CONST $cbops.mux_1to2_op.STRUC_SIZE 3;


   .CONST $cbops.demux_2to1_op.PTR_STATE_FIELD 0;
   .CONST $cbops.demux_2to1_op.PREV_TRUE_FIELD 1;
   .CONST $cbops.demux_2to1_op.PREV_FALSE_FIELD 2;
   .CONST $cbops.demux_2to1_op.STRUC_SIZE 3;
.linefile 43 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_compress_copy_op.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_compress_copy_op.h"
   .CONST $cbops.compress_copy_op.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.compress_copy_op.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.compress_copy_op.SHIFT_AMOUNT 2;
   .CONST $cbops.compress_copy_op.STRUC_SIZE 3;

   .CONST $COMPRESS_RANGE 0.1087;
.linefile 44 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_dc_remove.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_dc_remove.h"
   .CONST $cbops.dc_remove.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.dc_remove.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.dc_remove.DC_ESTIMATE_FIELD 2;
   .CONST $cbops.dc_remove.STRUC_SIZE 3;



   .CONST $cbops.dc_remove.FILTER_COEF 0.0005;
.linefile 45 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_av_copy_op.h" 1




.CONST $cbops.av_copy_op.INPUT_LEFT_INDEX_FIELD 0;
.CONST $cbops.av_copy_op.INPUT_RIGHT_INDEX_FIELD 1;
.CONST $cbops.av_copy_op.OUTPUT_LEFT_INDEX_FIELD 2;
.CONST $cbops.av_copy_op.OUTPUT_RIGHT_INDEX_FIELD 3;
.CONST $cbops.av_copy_op.AVERAGE_DATA_FIELD 4;
.CONST $cbops.av_copy_op.PREV_PORT_SPACE_FIELD 5;
.CONST $cbops.av_copy_op.PREV_BUFFER_PTR_FIELD 6;
.CONST $cbops.av_copy_op.READ_ADDR_COUNTER_FIELD 7;
.CONST $cbops.av_copy_op.AMOUNT_DATA_BUF_LEFT 8;
.CONST $cbops.av_copy_op.AMOUNT_DATA_BUF_RIGHT 9;
.CONST $cbops.av_copy_op.STRUC_SIZE 10;


.CONST $CBOPS_AV_COPY_INITIAL_AVERAGE 5800;
.linefile 46 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_stereo_sync_op.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_stereo_sync_op.h"
   .CONST $cbops.stereo_sync_op.START1_INDEX_FIELD 0;
   .CONST $cbops.stereo_sync_op.START2_INDEX_FIELD 1;
   .CONST $cbops.stereo_sync_op.STRUC_SIZE 2;
.linefile 47 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_sidetone_filter_operator.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_sidetone_filter_operator.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/peq.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/peq.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbuffer.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbuffer.h"
   .CONST $cbuffer.SIZE_FIELD 0;
   .CONST $cbuffer.READ_ADDR_FIELD 1;
   .CONST $cbuffer.WRITE_ADDR_FIELD 2;




      .CONST $cbuffer.STRUC_SIZE 3;




 .CONST $frmbuffer.CBUFFER_PTR_FIELD 0;
 .CONST $frmbuffer.FRAME_PTR_FIELD 1;
 .CONST $frmbuffer.FRAME_SIZE_FIELD 2;
 .CONST $frmbuffer.STRUC_SIZE 3;
.linefile 42 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbuffer.h"
      .CONST $cbuffer.NUM_PORTS 12;
      .CONST $cbuffer.WRITE_PORT_OFFSET 0x00000C;
      .CONST $cbuffer.PORT_NUMBER_MASK 0x00000F;
      .CONST $cbuffer.TOTAL_PORT_NUMBER_MASK 0x00001F;
      .CONST $cbuffer.TOTAL_CONTINUOUS_PORTS 8;







   .CONST $cbuffer.MMU_PAGE_SIZE 64;


   .CONST $cbuffer.READ_PORT_MASK 0x800000;
   .CONST $cbuffer.WRITE_PORT_MASK $cbuffer.READ_PORT_MASK + $cbuffer.WRITE_PORT_OFFSET;




   .CONST $cbuffer.FORCE_ENDIAN_MASK 0x300000;
   .CONST $cbuffer.FORCE_ENDIAN_SHIFT_AMOUNT -21;
   .CONST $cbuffer.FORCE_LITTLE_ENDIAN 0x100000;
   .CONST $cbuffer.FORCE_BIG_ENDIAN 0x300000;


   .CONST $cbuffer.FORCE_SIGN_EXTEND_MASK 0x0C0000;
   .CONST $cbuffer.FORCE_SIGN_EXTEND_SHIFT_AMOUNT -19;
   .CONST $cbuffer.FORCE_SIGN_EXTEND 0x040000;
   .CONST $cbuffer.FORCE_NO_SIGN_EXTEND 0x0C0000;


   .CONST $cbuffer.FORCE_BITWIDTH_MASK 0x038000;
   .CONST $cbuffer.FORCE_BITWIDTH_SHIFT_AMOUNT -16;
   .CONST $cbuffer.FORCE_8BIT_WORD 0x008000;
   .CONST $cbuffer.FORCE_16BIT_WORD 0x018000;
   .CONST $cbuffer.FORCE_24BIT_WORD 0x028000;
   .CONST $cbuffer.FORCE_32BIT_WORD 0x038000;


   .CONST $cbuffer.FORCE_SATURATE_MASK 0x006000;
   .CONST $cbuffer.FORCE_SATURATE_SHIFT_AMOUNT -14;
   .CONST $cbuffer.FORCE_NO_SATURATE 0x002000;
   .CONST $cbuffer.FORCE_SATURATE 0x006000;


   .CONST $cbuffer.FORCE_PADDING_MASK 0x001C00;
   .CONST $cbuffer.FORCE_PADDING_SHIFT_AMOUNT -11;
   .CONST $cbuffer.FORCE_PADDING_NONE 0x000400;
   .CONST $cbuffer.FORCE_PADDING_LS_BYTE 0x000C00;
   .CONST $cbuffer.FORCE_PADDING_MS_BYTE 0x001400;


   .CONST $cbuffer.FORCE_PCM_AUDIO $cbuffer.FORCE_LITTLE_ENDIAN +
                                                      $cbuffer.FORCE_SIGN_EXTEND +
                                                      $cbuffer.FORCE_SATURATE;
   .CONST $cbuffer.FORCE_24B_PCM_AUDIO $cbuffer.FORCE_LITTLE_ENDIAN +
                                                      $cbuffer.FORCE_32BIT_WORD +
                                                      $cbuffer.FORCE_PADDING_MS_BYTE +
                                                      $cbuffer.FORCE_NO_SATURATE;

   .CONST $cbuffer.FORCE_16BIT_DATA_STREAM $cbuffer.FORCE_BIG_ENDIAN +
                                                      $cbuffer.FORCE_NO_SIGN_EXTEND +
                                                      $cbuffer.FORCE_NO_SATURATE;
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/peq.h" 2







    .CONST $audio_proc.peq.parameter.NUM_STAGES_FIELD 0;
    .CONST $audio_proc.peq.parameter.GAIN_EXPONENT_FIELD 1;
    .CONST $audio_proc.peq.parameter.GAIN_MANTISA__FIELD 2;
    .CONST $audio_proc.peq.parameter.STAGES_SCALES 3;







   .CONST $audio_proc.peq.INPUT_ADDR_FIELD 0;


   .CONST $audio_proc.peq.OUTPUT_ADDR_FIELD 1;


   .CONST $audio_proc.peq.MAX_STAGES_FIELD 2;

   .CONST $audio_proc.peq.PARAM_PTR_FIELD 3;



   .CONST $audio_proc.peq.DELAYLINE_ADDR_FIELD 4;
.linefile 50 "C:/ADK3.5/kalimba/lib_sets/sdk/include/peq.h"
   .CONST $audio_proc.peq.COEFS_ADDR_FIELD 5;




   .CONST $audio_proc.peq.NUM_STAGES_FIELD 6;



   .CONST $audio_proc.peq.DELAYLINE_SIZE_FIELD 7;



   .CONST $audio_proc.peq.COEFS_SIZE_FIELD 8;


   .CONST $audio_proc.peq.STRUC_SIZE 9;






   .CONST $audio_proc.peq.const.NUM_STAGES_MASK 0xFF;
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_sidetone_filter_operator.h" 2




.CONST $cbops.sidetone_filter_op.Parameter.OFFSET_ST_CLIP_POINT 0;

.CONST $cbops.sidetone_filter_op.Parameter.OFFSET_ST_ADJUST_LIMIT 1;




.CONST $cbops.sidetone_filter_op.Parameter.OFFSET_STF_SWITCH 2;

.CONST $cbops.sidetone_filter_op.Parameter.OFFSET_STF_NOISE_LOW_THRES 3;

.CONST $cbops.sidetone_filter_op.Parameter.OFFSET_STF_NOISE_HIGH_THRES 4;

.CONST $cbops.sidetone_filter_op.Parameter.OFFSET_STF_GAIN_EXP 5;
.CONST $cbops.sidetone_filter_op.Parameter.OFFSET_STF_GAIN_MANTISSA 6;

.CONST $cbops.sidetone_filter_op.Parameter.BLOCKSIZE 7;



.CONST $cbops.sidetone_filter_op.INPUT_START_INDEX_FIELD 0;
.CONST $cbops.sidetone_filter_op.OUTPUT_START_INDEX_FIELD 1;
.CONST $cbops.sidetone_filter_op.ENABLE_MASK_FIELD 2;
.CONST $cbops.sidetone_filter_op.PARAM_PTR_FIELD 3;

.CONST $cbops.sidetone_filter_op.APPLY_FILTER 4;
.CONST $cbops.sidetone_filter_op.APPLY_GAIN_FIELD 5;


.CONST $cbops.sidetone_filter_op.NOISE_LEVEL_PTR_FIELD 6;

.CONST $cbops.sidetone_filter_op.OFFSET_ST_CONFIG_FIELD 7;

.CONST $cbops.sidetone_filter_op.OFFSET_PTR_INV_DAC_GAIN 8;

.CONST $cbops.sidetone_filter_op.OFFSET_CURRENT_SIDETONE_GAIN 9;

.CONST $cbops.sidetone_filter_op.OFFSET_PEAK_ST 10;

.CONST $cbops.sidetone_filter_op.PEQ_START_FIELD 11;
.linefile 49 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_sidetone_mix_operator.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_sidetone_mix_operator.h"
   .CONST $cbops.sidetone_mix_op.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.sidetone_mix_op.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.sidetone_mix_op.SIDETONE_START_INDEX_FIELD 2;
   .CONST $cbops.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD 3;
   .CONST $cbops.sidetone_mix_op.ATTENUATION_PTR_FIELD 4;
   .CONST $cbops.sidetone_mix_op.STRUC_SIZE 5;
.linefile 50 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_hw_warp_operator.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_hw_warp_operator.h"
.CONST $cbops.hw_warp_op.PORT_OFFSET 0;
.CONST $cbops.hw_warp_op.MONITOR_INDEX_OFFSET 1;
.CONST $cbops.hw_warp_op.WHICH_PORTS_OFFSET 2;
.CONST $cbops.hw_warp_op.TARGET_RATE_OFFSET 3;
.CONST $cbops.hw_warp_op.PERIODS_PER_SECOND_OFFSET 4;
.CONST $cbops.hw_warp_op.COLLECT_SECONDS_OFFSET 5;
.CONST $cbops.hw_warp_op.ENABLE_DITHER_OFFSET 6;

.CONST $cbops.hw_warp_op.ACCUMULATOR_OFFSET 7;
.CONST $cbops.hw_warp_op.PERIOD_COUNTER_OFFSET 8;
.CONST $cbops.hw_warp_op.LAST_WARP_OFFSET 9;

.CONST $cbops.hw_warp_op.STRUC_SIZE 10;
.linefile 51 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_aux_mix_operator.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_aux_mix_operator.h"
   .CONST $cbops.aux_audio_mix_op.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.aux_audio_mix_op.OUTPUT_START_INDEX_FIELD 1;

   .CONST $cbops.aux_audio_mix_op.TONE_PORT_FIELD 2;
   .CONST $cbops.aux_audio_mix_op.TONE_BUFFER_FIELD 3;

   .CONST $cbops.aux_audio_mix_op.TIMER_FIELD 4;
   .CONST $cbops.aux_audio_mix_op.TIMER_HOLD_FIELD 5;
   .CONST $cbops.aux_audio_mix_op.AUX_GAIN_FIELD 6;
   .CONST $cbops.aux_audio_mix_op.PRIM_GAIN_FIELD 7;
   .CONST $cbops.aux_audio_mix_op.OFFSET_INV_DAC_GAIN 8;

   .CONST $cbops.aux_audio_mix_op.CLIP_POINT_FIELD 9;
   .CONST $cbops.aux_audio_mix_op.BOOST_CLIP_POINT_FIELD 10;
   .CONST $cbops.aux_audio_mix_op.BOOST_FIELD 11;
   .CONST $cbops.aux_audio_mix_op.PEAK_AUXVAL_FIELD 12;
   .CONST $cbops.aux_audio_mix_op.AUX_GAIN_ADJUST_FIELD 13;
   .CONST $cbops.aux_audio_mix_op.INTERNAL_BUF_PTR_FIELD 14;

   .CONST $cbops.aux_audio_mix_op.STRUC_SIZE 15;
.linefile 52 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_port_wrap_op.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_port_wrap_op.h"
.CONST $cbops.port_wrap_op.OUTPUT1_INDEX_FIELD 0;
.CONST $cbops.port_wrap_op.OUTPUT2_INDEX_FIELD 1;
.CONST $cbops.port_wrap_op.BUFFER_ADJUST_FIELD 2;
.CONST $cbops.port_wrap_op.MAX_ADVANCE_FIELD 3;
.CONST $cbops.port_wrap_op.SYNC_INDEX_FIELD 4;

.CONST $cbops.port_wrap_op.WRAP_COUNT_FIELD 5;
.CONST $cbops.port_wrap_op.STRUC_SIZE 6;
.linefile 53 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_insert_op.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_insert_op.h"
.CONST $cbops.insert_op.BUFFER_INDEX_FIELD 0;
.CONST $cbops.insert_op.MAX_ADVANCE_FIELD 1;

.CONST $cbops.insert_op.DATA_AMOUNT_FIELD 2;
.CONST $cbops.insert_op.STRUC_SIZE 3;



.CONST $cbops.insert_copy_op.INPUT_BUFFER_INDEX_FIELD 0;
.CONST $cbops.insert_copy_op.OUTPUT_BUFFER_INDEX_FIELD 1;
.CONST $cbops.insert_copy_op.MAX_ADVANCE_FIELD 2;
.CONST $cbops.insert_copy_op.STRUC_SIZE 3;
.linefile 54 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_rate_moniter_op.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_rate_moniter_op.h"
.CONST $cbops.rate_monitor_op.MONITOR_INDEX_FIELD 0;
.CONST $cbops.rate_monitor_op.PERIODS_PER_SECOND_FIELD 1;
.CONST $cbops.rate_monitor_op.SECONDS_TRACKED_FIELD 2;
.CONST $cbops.rate_monitor_op.TARGET_RATE_FIELD 3;
.CONST $cbops.rate_monitor_op.ALPHA_LIMIT_FIELD 4;
.CONST $cbops.rate_monitor_op.AVERAGE_IO_RATIO_FIELD 5;
.CONST $cbops.rate_monitor_op.WARP_MSG_LIMIT_FIELD 6;
.CONST $cbops.rate_monitor_op.IDLE_PERIODS_AFTER_STALL_FIELD 7;


.CONST $cbops.rate_monitor_op.ACCUMULATOR_FIELD 8;
.CONST $cbops.rate_monitor_op.COUNTER_FIELD 9;
.CONST $cbops.rate_monitor_op.STALL_FIELD 10;
.CONST $cbops.rate_monitor_op.LAST_ACCUMULATION_FIELD 11;
.CONST $cbops.rate_monitor_op.CURRENT_ALPHA_INDEX_FIELD 12;
.CONST $cbops.rate_monitor_op.INVERSE_WARP_VALUE_FIELD 13;
.CONST $cbops.rate_monitor_op.WARP_VALUE_FIELD 14;
.CONST $cbops.rate_monitor_op.WARP_MSG_COUNTER_FIELD 15;

.CONST $cbops.rate_monitor_op.DEBUG_STALL_COUNT_FIELD 16;
.CONST $cbops.rate_monitor_op.DEBUG_LAST_PERIOD_COUNT_FIELD 17;
.CONST $cbops.rate_monitor_op.DEBUG_TIMER_PERIOD_FIELD 18;
.CONST $cbops.rate_monitor_op.DEBUG_ALG_RESTART_COUNT_FIELD 19;
.CONST $cbops.rate_monitor_op.DEBUG_INSTANTANEOUS_IO_RATIO_FIELD 20;

.CONST $cbops.rate_monitor_op.STRUC_SIZE 21;


.CONST $cbops.rate_monitor_op.NO_DATA_PERIODS_FOR_STALL 3;
.CONST $cbops.rate_monitor_op.ALG_RESTART_THRESHOLD 0.0005;
.linefile 55 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_usb_op.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_usb_op.h"
.CONST $cbops.usb_in_op.INPUT_INDEX_FIELD 0;
.CONST $cbops.usb_in_op.OUTPUT1_INDEX_FIELD 1;
.CONST $cbops.usb_in_op.OUTPUT2_INDEX_FIELD 2;
.CONST $cbops.usb_in_op.PKT_LENGTH_FIELD 3;
.CONST $cbops.usb_in_op.LAST_HEADER_FIELD 4;
.CONST $cbops.usb_in_op.STRUC_SIZE 5;

.CONST $cbops.usb_out_op.INPUT1_INDEX_FIELD 0;
.CONST $cbops.usb_out_op.INPUT2_INDEX_FIELD 1;
.CONST $cbops.usb_out_op.OUTPUT_INDEX_FIELD 2;
.CONST $cbops.usb_out_op.PACKET_PERIOD_FIELD 3;
.CONST $cbops.usb_out_op.STALL_COUNT_FIELD 4;
.CONST $cbops.usb_out_op.LAST_LIMIT_FIELD 5;
.CONST $cbops.usb_out_op.PACKET_BUFFER_DATA_FIELD 6;
.CONST $cbops.usb_out_op.PACKET_BUFFER_START_FIELD 7;
.CONST $cbops.usb_out_op.STRUC_SIZE 7;


.CONST $CBOPS_USB_STALL_CNT_THRESH 7;
.linefile 56 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_conditional_op.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_conditional_op.h"
   .CONST $cbops.conditional_op.MASK_FIELD 0;
   .CONST $cbops.conditional_op.COND_PTR_FIELD 1;
   .CONST $cbops.conditional_op.OP_PTR_FIELD 2;
   .CONST $cbops.conditional_op.STRUC_SIZE 3;
.linefile 57 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_s_to_m_op.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_s_to_m_op.h"
   .CONST $cbops.s_to_m_op.INPUT_LEFT_INDEX_FIELD 0;
   .CONST $cbops.s_to_m_op.INPUT_RIGHT_INDEX_FIELD 1;
   .CONST $cbops.s_to_m_op.OUTPUT_MONO_INDEX_FIELD 2;
   .CONST $cbops.s_to_m_op.STRUC_SIZE 3;
.linefile 58 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_soft_mute_op.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_soft_mute_op.h"
    .const $cbops.soft_mute_op.INPUT_START_INDEX_FIELD 0;
    .const $cbops.soft_mute_op.OUTPUT_START_INDEX_FIELD 1;
    .const $cbops.soft_mute_op.MUTE_DIRECTION 2;
    .const $cbops.soft_mute_op.MUTE_INDEX 3;
 .const $cbops.soft_mute_op.STRUC_SIZE 4;
.linefile 59 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_cmpd_op.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_cmpd_op.h"
.CONST $cbops.cmpd_op.Parameter.OFFSET_EXPAND_THRESHOLD 0;
.CONST $cbops.cmpd_op.Parameter.OFFSET_LINEAR_THRESHOLD 1;
.CONST $cbops.cmpd_op.Parameter.OFFSET_COMPRESS_THRESHOLD 2;
.CONST $cbops.cmpd_op.Parameter.OFFSET_LIMIT_THRESHOLD 3;
.CONST $cbops.cmpd_op.Parameter.OFFSET_INV_EXPAND_RATIO 4;
.CONST $cbops.cmpd_op.Parameter.OFFSET_INV_LINEAR_RATIO 5;
.CONST $cbops.cmpd_op.Parameter.OFFSET_INV_COMPRESS_RATIO 6;
.CONST $cbops.cmpd_op.Parameter.OFFSET_INV_LIMIT_RATIO 7;
.CONST $cbops.cmpd_op.Parameter.OFFSET_EXPAND_ATTACK_TC 8;
.CONST $cbops.cmpd_op.Parameter.OFFSET_EXPAND_DECAY_TC 9;
.CONST $cbops.cmpd_op.Parameter.OFFSET_LINEAR_ATTACK_TC 10;
.CONST $cbops.cmpd_op.Parameter.OFFSET_LINEAR_DECAY_TC 11;
.CONST $cbops.cmpd_op.Parameter.OFFSET_COMPRESS_ATTACK_TC 12;
.CONST $cbops.cmpd_op.Parameter.OFFSET_COMPRESS_DECAY_TC 13;
.CONST $cbops.cmpd_op.Parameter.OFFSET_LIMIT_ATTACK_TC 14;
.CONST $cbops.cmpd_op.Parameter.OFFSET_LIMIT_DECAY_TC 15;
.CONST $cbops.cmpd_op.Parameter.OFFSET_MAKEUP_GAIN 16;
.CONST $cbops.cmpd_op.Parameter.STRUC_SIZE 17;


.CONST $cbops.cmpd_op.INPUT_1_START_INDEX_FIELD 0;
.CONST $cbops.cmpd_op.INPUT_2_START_INDEX_FIELD 1;
.CONST $cbops.cmpd_op.OUTPUT_1_START_INDEX_FIELD 2;
.CONST $cbops.cmpd_op.OUTPUT_2_START_INDEX_FIELD 3;
.CONST $cbops.cmpd_op.OFFSET_PARAM_PTR 4;
.CONST $cbops.cmpd_op.OFFSET_SAMPLES_FOR_PROCESS 5;
.CONST $cbops.cmpd_op.OFFSET_GAIN_PTR 6;
.CONST $cbops.cmpd_op.OFFSET_NEG_ONE 7;
.CONST $cbops.cmpd_op.OFFSET_POW2_NEG4 8;

.CONST $cbops.cmpd_op.OFFSET_EXPAND_CONSTANT 9;
.CONST $cbops.cmpd_op.OFFSET_LINEAR_CONSTANT 10;
.CONST $cbops.cmpd_op.OFFSET_COMPRESS_CONSTANT 11;
.CONST $cbops.cmpd_op.OFFSET_PEAK 12;
.CONST $cbops.cmpd_op.OFFSET_LOG_PEAK 13;
.CONST $cbops.cmpd_op.OFFSET_REGION 14;
.CONST $cbops.cmpd_op.OFFSET_INST_GAIN 15;
.CONST $cbops.cmpd_op.OFFSET_SAMPLE_COUNT 16;
.CONST $cbops.cmpd_op.STRUC_SIZE 17;
.linefile 60 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_eq.h" 1
.linefile 16 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_eq.h"
   .CONST $cbops.eq.parameter.INPUT_GAIN_EXPONENT_PTR 0;
   .CONST $cbops.eq.parameter.INPUT_GAIN_MANTISA_PTR 1;
   .CONST $cbops.eq.parameter.NUM_STAGES_FIELD 2;
   .CONST $cbops.eq.parameter.STAGES_SCALES 3;



   .CONST $cbops.eq.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.eq.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.eq.PEQ_START_FIELD 2;
.linefile 61 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_stereo_3d_enhancement.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_stereo_3d_enhancement.h"
.CONST $cbops.stereo_3d_enhancement_op.INPUT_1_START_INDEX_FIELD 0;
.CONST $cbops.stereo_3d_enhancement_op.INPUT_2_START_INDEX_FIELD 1;
.CONST $cbops.stereo_3d_enhancement_op.OUTPUT_1_START_INDEX_FIELD 2;
.CONST $cbops.stereo_3d_enhancement_op.OUTPUT_2_START_INDEX_FIELD 3;
.CONST $cbops.stereo_3d_enhancement_op.DELAY_1_STRUC_FIELD 4;
.CONST $cbops.stereo_3d_enhancement_op.DELAY_2_STRUC_FIELD 5;
.CONST $cbops.stereo_3d_enhancement_op.COEFF_STRUC_FIELD 6;
.CONST $cbops.stereo_3d_enhancement_op.REFLECTION_DELAY_SAMPLES_FIELD 7;
.CONST $cbops.stereo_3d_enhancement_op.MIX_FIELD 8;
.CONST $cbops.stereo_3d_enhancement_op.STRUC_SIZE 9;


.CONST $cbops.stereo_3d_enhancement_op.REFLECTION_DELAY 618;






.CONST $cbops.stereo_3d_enhancement_op.DELAY_BUFFER_SIZE 2048;
.linefile 62 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_volume.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_volume.h"
   .CONST $cbops.volume.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.volume.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.volume.FINAL_VALUE_FIELD 2;
   .CONST $cbops.volume.CURRENT_VALUE_FIELD 3;
   .CONST $cbops.volume.SAMPLES_PER_STEP_FIELD 4;
   .CONST $cbops.volume.STEP_SHIFT_FIELD 5;
   .CONST $cbops.volume.DELTA_FIELD 6;
   .CONST $cbops.volume.CURRENT_STEP_FIELD 7;
   .CONST $cbops.volume.STRUC_SIZE 8;
.linefile 63 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_peak_monitor_op.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_peak_monitor_op.h"
   .CONST $cbops.peak_monitor_op.PTR_INPUT_BUFFER_FIELD 0;
   .CONST $cbops.peak_monitor_op.PEAK_LEVEL_PTR 1;
   .CONST $cbops.peak_monitor_op.STRUC_SIZE 2;
.linefile 64 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_signal_detect.h" 1
.linefile 16 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_signal_detect.h"
    .const $cbops.signal_detect_op.LINEAR_THRESHOLD_VALUE 0;
    .const $cbops.signal_detect_op.NO_SIGNAL_TRIGGER_TIME 1;
    .const $cbops.signal_detect_op.CURRENT_MAX_VALUE 2;
    .const $cbops.signal_detect_op.SECOND_TIMER 3;
    .const $cbops.signal_detect_op.SIGNAL_STATUS 4;
    .const $cbops.signal_detect_op.SIGNAL_STATUS_MSG_ID 5;
    .const $cbops.signal_detect_op.NUM_CHANNELS 6;
    .const $cbops.signal_detect_op.FIRST_CHANNEL_INDEX 7;
    .const $cbops.signal_detect_op.STRUC_SIZE_MONO 8;
    .const $cbops.signal_detect_op.STRUC_SIZE_STEREO 9;
    .const $cbops.signal_detect_op.STRUC_SIZE_3_CHANNEL 10;
.linefile 65 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_deinterleave_mix.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_deinterleave_mix.h"
   .CONST $cbops.deinterleave_mix.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.deinterleave_mix.OUTPUT1_START_INDEX_FIELD 1;
   .CONST $cbops.deinterleave_mix.OUTPUT2_START_INDEX_FIELD 2;
   .CONST $cbops.deinterleave_mix.INPUT_INTERLEAVED_FIELD 3;
   .CONST $cbops.deinterleave_mix.STRUC_SIZE 4;
.linefile 66 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_fir_resample.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/cbops_fir_resample.h"
   .CONST $cbops.fir_resample.INPUT_INDEX_FIELD 0;
   .CONST $cbops.fir_resample.OUTPUT_INDEX_FIELD 1;
   .CONST $cbops.fir_resample.COEF_BUF_INDEX_FIELD 2;
   .CONST $cbops.fir_resample.INPUT_RATE_ADDR_FIELD 3;
   .CONST $cbops.fir_resample.OUTPUT_RATE_ADDR_FIELD 4;
   .CONST $cbops.fir_resample.HIST_BUF_FIELD 5;
   .CONST $cbops.fir_resample.CURRENT_OUTPUT_RATE_FIELD 6;
   .CONST $cbops.fir_resample.CURRENT_INPUT_RATE_FIELD 7;
   .CONST $cbops.fir_resample.CONVERT_RATIO_INT_FIELD 8;
   .CONST $cbops.fir_resample.CONVERT_RATIO_FRAC_FIELD 9;
   .CONST $cbops.fir_resample.IR_RATIO_FIELD 10;
   .CONST $cbops.fir_resample.INT_SAMPLES_LEFT_FIELD 11;
   .CONST $cbops.fir_resample.RESAMPLE_UNITY_RATIO_FIELD 12;

   .CONST $cbops.fir_resample.STRUC_SIZE 13;


   .CONST $cbops.fir_resample.HIST_LENGTH ($cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE+1);
   .CONST $cbops.fir_resample.FILTER_LENGTH $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE;
   .CONST $cbops.fir_resample.FILTER_UPRATE $cbops.rate_adjustment_and_shift.SRA_UPRATE;
.linefile 67 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/iir_resamplev2/iir_resamplev2_header.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/multirate_operators/iir_resamplev2/iir_resamplev2_header.h"
   .CONST $iir_resamplev2.INPUT_1_START_INDEX_FIELD 0;
   .CONST $iir_resamplev2.OUTPUT_1_START_INDEX_FIELD 1;

   .CONST $iir_resamplev2.FILTER_DEFINITION_PTR_FIELD 2;
   .CONST $iir_resamplev2.INPUT_SCALE_FIELD 3;
   .CONST $iir_resamplev2.OUTPUT_SCALE_FIELD 4;

   .CONST $iir_resamplev2.INTERMEDIATE_CBUF_PTR_FIELD 5;
   .CONST $iir_resamplev2.INTERMEDIATE_CBUF_LEN_FIELD 6;

   .CONST $iir_resamplev2.PARTIAL1_FIELD 7;
   .CONST $iir_resamplev2.SAMPLE_COUNT1_FIELD 8;
   .CONST $iir_resamplev2.FIR_HISTORY_BUF1_PTR_FIELD 9;
   .CONST $iir_resamplev2.IIR_HISTORY_BUF1_PTR_FIELD 10;

   .CONST $iir_resamplev2.PARTIAL2_FIELD 11;
   .CONST $iir_resamplev2.SAMPLE_COUNT2_FIELD 12;
   .CONST $iir_resamplev2.FIR_HISTORY_BUF2_PTR_FIELD 13;
   .CONST $iir_resamplev2.IIR_HISTORY_BUF2_PTR_FIELD 14;

   .CONST $iir_resamplev2.RESET_FLAG_FIELD 15;
   .CONST $iir_resamplev2.STRUC_SIZE 16;



   .CONST $cbops.complete.iir_resamplev2.STRUC_SIZE 1;




   .CONST $IIR_RESAMPLEV2_IIR_BUFFER_SIZE 19;
   .CONST $IIR_RESAMPLEV2_FIR_BUFFER_SIZE 10;
   .CONST $IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE ($IIR_RESAMPLEV2_IIR_BUFFER_SIZE+$IIR_RESAMPLEV2_FIR_BUFFER_SIZE);
   .CONST $iir_resamplev2.OBJECT_SIZE $iir_resamplev2.STRUC_SIZE + 2*$IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE;

   .CONST $iir_resamplev2.OBJECT_SIZE_SNGL_STAGE $iir_resamplev2.STRUC_SIZE + $IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE;
.linefile 68 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_multirate_library.h" 2
.linefile 36 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 1
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules_library.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules_library.h"
.CONST $CVC_VERSION 0x0001;
.linefile 16 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/aec500/aec500_library.h" 1
.linefile 16 "C:/ADK3.5/kalimba/lib_sets/sdk/include/aec500/aec500_library.h"
.CONST $AEC_500_VERSION 0x001000;


.CONST $M.AEC_500.CALLST.CONNECTING 2;


.CONST $M.AEC_500.AEC_L2Px_HB 0xF80000;


.CONST $M.AEC_500.L_MUA_ON 0xFF0000;
.CONST $M.AEC_500_HF.L_MUA_ON 0xFD0000;


.CONST $M.AEC_500.L_ALFA_A 0xFEA782;
.CONST $M.AEC_500_HF.L_ALFA_A 0xFCE929;


.CONST $M.AEC_500.CNG_G_ADJUST 0x727C97;


.CONST $M.AEC_500.Num_Auxillary_Taps 0;
.CONST $M.AEC_500_HF.Num_Auxillary_Taps 3;

.CONST $M.AEC_500.Num_Primary_Taps 2;
.CONST $M.AEC_500_HF.Num_Primary_Taps 8;

.CONST $M.AEC_500.RER_dim 64;


.CONST $M.AEC_500_WB.Num_HFK_Freq_Bins 129;
.CONST $M.AEC_500_WB.LPwrX_margin.overflow_bits -4;
.CONST $M.AEC_500_WB.LPwrX_margin.scale_factor (16.0/129.0);

.CONST $M.AEC_500_NB.Num_HFK_Freq_Bins 65;
.CONST $M.AEC_500_NB.LPwrX_margin.overflow_bits -3;
.CONST $M.AEC_500_NB.LPwrX_margin.scale_factor (8.0/65.0);
.linefile 60 "C:/ADK3.5/kalimba/lib_sets/sdk/include/aec500/aec500_library.h"
.CONST $M.AEC_500.OFFSET_E_REAL_PTR 0;


.CONST $M.AEC_500.OFFSET_E_IMAG_PTR $M.AEC_500.OFFSET_E_REAL_PTR +1;


.CONST $M.AEC_500.OFFSET_D_EXP_PTR $M.AEC_500.OFFSET_E_IMAG_PTR+1;


.CONST $M.AEC_500.OFFSET_D_REAL_PTR $M.AEC_500.OFFSET_D_EXP_PTR+1;


.CONST $M.AEC_500.OFFSET_D_IMAG_PTR $M.AEC_500.OFFSET_D_REAL_PTR +1;


.CONST $M.AEC_500.OFFSET_SCRPTR_Exp_Mts_adapt $M.AEC_500.OFFSET_D_IMAG_PTR+1;





.CONST $M.AEC_500.OFFSET_RER_EXT_FUNC_PTR $M.AEC_500.OFFSET_SCRPTR_Exp_Mts_adapt+1;

.CONST $M.AEC_500.OFFSET_RER_D_REAL_PTR $M.AEC_500.OFFSET_RER_EXT_FUNC_PTR+1;

.CONST $M.AEC_500.OFFSET_RER_D_IMAG_PTR $M.AEC_500.OFFSET_RER_D_REAL_PTR +1;


.CONST $M.AEC_500.OFFSET_PTR_Gr_imag $M.AEC_500.OFFSET_RER_D_IMAG_PTR+1;


.CONST $M.AEC_500.OFFSET_PTR_Gr_real $M.AEC_500.OFFSET_PTR_Gr_imag+1;


.CONST $M.AEC_500.OFFSET_PTR_SqGr $M.AEC_500.OFFSET_PTR_Gr_real+1;


.CONST $M.AEC_500.OFFSET_PTR_L2absGr $M.AEC_500.OFFSET_PTR_SqGr+1;


.CONST $M.AEC_500.OFFSET_PTR_LPwrD $M.AEC_500.OFFSET_PTR_L2absGr +1;


.CONST $M.AEC_500.OFFSET_SCRPTR_W_ri $M.AEC_500.OFFSET_PTR_LPwrD +1;


.CONST $M.AEC_500.OFFSET_SCRPTR_L_adaptR $M.AEC_500.OFFSET_SCRPTR_W_ri +1;


.CONST $M.AEC_500.OFFSET_RER_SQGRDEV $M.AEC_500.OFFSET_SCRPTR_L_adaptR +1;




.CONST $M.AEC_500.OFFSET_X_REAL_PTR $M.AEC_500.OFFSET_RER_SQGRDEV +1;


.CONST $M.AEC_500.OFFSET_X_IMAG_PTR $M.AEC_500.OFFSET_X_REAL_PTR +1;


.CONST $M.AEC_500.OFFSET_X_EXP_PTR $M.AEC_500.OFFSET_X_IMAG_PTR +1;


.CONST $M.AEC_500.OFFSET_OMS1_G_PTR $M.AEC_500.OFFSET_X_EXP_PTR +1;


.CONST $M.AEC_500.OFFSET_OMS1_D_NZ_PTR $M.AEC_500.OFFSET_OMS1_G_PTR +1;


.CONST $M.AEC_500.OFFSET_oms_adapt_G_PTR $M.AEC_500.OFFSET_OMS1_D_NZ_PTR +1;


.CONST $M.AEC_500.OFFSET_OMS2_G_PTR $M.AEC_500.OFFSET_oms_adapt_G_PTR +1;


.CONST $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS $M.AEC_500.OFFSET_OMS2_G_PTR +1;


.CONST $M.AEC_500.OFFSET_CNG_Q_ADJUST $M.AEC_500.OFFSET_OMS_AGGRESSIVENESS +1;

.CONST $M.AEC_500.OFFSET_CNG_G_ADJUST $M.AEC_500.OFFSET_CNG_Q_ADJUST +1;


.CONST $M.AEC_500.OFFSET_DTC_AGRESSIVENESS $M.AEC_500.OFFSET_CNG_G_ADJUST +1;

.CONST $M.AEC_500.OFFSET_RER_WGT_L2PXR $M.AEC_500.OFFSET_DTC_AGRESSIVENESS +1;

.CONST $M.AEC_500.OFFSET_RER_WGT_L2PDR $M.AEC_500.OFFSET_RER_WGT_L2PXR +1;




.CONST $M.AEC_500.OFFSET_ENABLE_AEC_REUSE $M.AEC_500.OFFSET_RER_WGT_L2PDR +1;


.CONST $M.AEC_500.OFFSET_CONFIG $M.AEC_500.OFFSET_ENABLE_AEC_REUSE +1;


.CONST $M.AEC_500.OFFSET_MAX_LPWR_MARGIN $M.AEC_500.OFFSET_CONFIG +1;


.CONST $M.AEC_500.OFFSET_NUM_AUXILLARY_TAPS $M.AEC_500.OFFSET_MAX_LPWR_MARGIN+1;

.CONST $M.AEC_500.OFFSET_NUM_PRIMARY_TAPS $M.AEC_500.OFFSET_NUM_AUXILLARY_TAPS+1;



.CONST $M.AEC_500.OFFSET_NUM_FREQ_BINS $M.AEC_500.OFFSET_NUM_PRIMARY_TAPS+1;




.CONST $M.AEC_500.OFFSET_LPWRX_MARGIN_OVFL $M.AEC_500.OFFSET_NUM_FREQ_BINS+1;




.CONST $M.AEC_500.OFFSET_LPWRX_MARGIN_SCL $M.AEC_500.OFFSET_LPWRX_MARGIN_OVFL+1;




.CONST $M.AEC_500.OFFSET_RERCBA_ENABLE_MASK $M.AEC_500.OFFSET_LPWRX_MARGIN_SCL+1;



.CONST $M.AEC_500.OFFSET_RER_AGGRESSIVENESS $M.AEC_500.OFFSET_RERCBA_ENABLE_MASK+1;


.CONST $M.AEC_500.OFFSET_RER_WGT_SY $M.AEC_500.OFFSET_RER_AGGRESSIVENESS+1;


.CONST $M.AEC_500.OFFSET_RER_OFFSET_SY $M.AEC_500.OFFSET_RER_WGT_SY+1;


.CONST $M.AEC_500.OFFSET_RER_POWER $M.AEC_500.OFFSET_RER_OFFSET_SY+1;



.CONST $M.AEC_500.OFFSET_AEC_REF_LPWR_HB $M.AEC_500.OFFSET_RER_POWER+1;





.CONST $M.AEC_500.OFFSET_SCRPTR_RERDT_DTC $M.AEC_500.OFFSET_AEC_REF_LPWR_HB+1;


.CONST $M.AEC_500.OFFSET_L2TH_RERDT_OFF $M.AEC_500.OFFSET_SCRPTR_RERDT_DTC+1;


.CONST $M.AEC_500.OFFSET_RERDT_ADJUST $M.AEC_500.OFFSET_L2TH_RERDT_OFF+1;


.CONST $M.AEC_500.OFFSET_RERDT_POWER $M.AEC_500.OFFSET_RERDT_ADJUST+1;





.CONST $M.AEC_500.OFFSET_AEC_L_MUA_ON $M.AEC_500.OFFSET_RERDT_POWER+1;



.CONST $M.AEC_500.OFFSET_AEC_L_ALFA_A $M.AEC_500.OFFSET_AEC_L_MUA_ON+1;






.CONST $M.AEC_500.OFFSET_DT_FUNC1_PTR $M.AEC_500.OFFSET_AEC_L_ALFA_A+1;



.CONST $M.AEC_500.OFFSET_DT_FUNC2_PTR $M.AEC_500.OFFSET_DT_FUNC1_PTR+1;



.CONST $M.AEC_500.OFFSET_DTC_AGRESS_FUNC_PTR $M.AEC_500.OFFSET_DT_FUNC2_PTR+1;



.CONST $M.AEC_500.OFFSET_LPWRX_UPDT_FUNC_PTR $M.AEC_500.OFFSET_DTC_AGRESS_FUNC_PTR+1;



.CONST $M.AEC_500.OFFSET_RER_DIVERGE_FUNC_PTR $M.AEC_500.OFFSET_LPWRX_UPDT_FUNC_PTR+1;




.CONST $M.AEC_500.OFFSET_CONST_DM1 $M.AEC_500.OFFSET_RER_DIVERGE_FUNC_PTR+1;




.CONST $M.AEC_500.OFFSET_PTR_RcvBuf_real $M.AEC_500.OFFSET_CONST_DM1+1;


.CONST $M.AEC_500.OFFSET_PTR_RcvBuf_imag $M.AEC_500.OFFSET_PTR_RcvBuf_real+1;


.CONST $M.AEC_500.OFFSET_PTR_Ga_imag $M.AEC_500.OFFSET_PTR_RcvBuf_imag+1;


.CONST $M.AEC_500.OFFSET_PTR_Ga_real $M.AEC_500.OFFSET_PTR_Ga_imag+1;



.CONST $M.AEC_500.OFFSET_PTR_Gb_imag $M.AEC_500.OFFSET_PTR_Ga_real+1;



.CONST $M.AEC_500.OFFSET_PTR_Gb_real $M.AEC_500.OFFSET_PTR_Gb_imag+1;


.CONST $M.AEC_500.OFFSET_PTR_L2PxR $M.AEC_500.OFFSET_PTR_Gb_real+1;


.CONST $M.AEC_500.OFFSET_PTR_BExp_Ga $M.AEC_500.OFFSET_PTR_L2PxR+1;



.CONST $M.AEC_500.OFFSET_PTR_BExp_Gb $M.AEC_500.OFFSET_PTR_BExp_Ga+1;


.CONST $M.AEC_500.OFFSET_PTR_LPwrX0 $M.AEC_500.OFFSET_PTR_BExp_Gb+1;


.CONST $M.AEC_500.OFFSET_PTR_RatFE $M.AEC_500.OFFSET_PTR_LPwrX0+1;


.CONST $M.AEC_500.OFFSET_PTR_BExp_X_buf $M.AEC_500.OFFSET_PTR_RatFE+1;


.CONST $M.AEC_500.OFFSET_PTR_LpZ_nz $M.AEC_500.OFFSET_PTR_BExp_X_buf+1;


.CONST $M.AEC_500.OFFSET_PTR_LPwrX1 $M.AEC_500.OFFSET_PTR_LpZ_nz+1;




.CONST $M.AEC_500.OFFSET_SCRPTR_Attenuation $M.AEC_500.OFFSET_PTR_LPwrX1+1;


.CONST $M.AEC_500.OFFSET_SCRPTR_L_adaptA $M.AEC_500.OFFSET_SCRPTR_Attenuation+1;



.CONST $M.AEC_500.OFFSET_SCRPTR_L_RatSqGt $M.AEC_500.OFFSET_SCRPTR_L_adaptA+1;


.CONST $M.AEC_500.OFFSET_L_DTC $M.AEC_500.OFFSET_SCRPTR_L_RatSqGt+1;


.CONST $M.AEC_500.OFFSET_CNG_NOISE_COLOR $M.AEC_500.OFFSET_L_DTC+1;




.CONST $M.AEC_500.OFFSET_PTR_NZ_TABLES $M.AEC_500.OFFSET_CNG_NOISE_COLOR+1;

.CONST $M.AEC_500.OFFSET_PTR_CUR_NZ_TABLE $M.AEC_500.OFFSET_PTR_NZ_TABLES+1;



.CONST $M.AEC_500.OFFSET_L_RatSqG $M.AEC_500.OFFSET_PTR_CUR_NZ_TABLE+1;
.CONST $M.AEC_500.OFFSET_dL2PxFB $M.AEC_500.OFFSET_L_RatSqG+1;
.CONST $M.AEC_500.OFFSET_Exp_D $M.AEC_500.OFFSET_dL2PxFB+1;
.CONST $M.AEC_500.OFFSET_L2Pxt0 $M.AEC_500.OFFSET_Exp_D+1;
.CONST $M.AEC_500.OFFSET_DTC_dLpX $M.AEC_500.OFFSET_L2Pxt0+1;
.CONST $M.AEC_500.OFFSET_DTC_LpXt_prev $M.AEC_500.OFFSET_DTC_dLpX+1;


.CONST $M.AEC_500.OFFSET_tt_dtc $M.AEC_500.OFFSET_DTC_LpXt_prev+1;
.CONST $M.AEC_500.OFFSET_ct_init $M.AEC_500.OFFSET_tt_dtc+1;
.CONST $M.AEC_500.OFFSET_ct_Px $M.AEC_500.OFFSET_ct_init+1;
.CONST $M.AEC_500.OFFSET_tt_cng $M.AEC_500.OFFSET_ct_Px+1;
.CONST $M.AEC_500.OFFSET_CNG_offset $M.AEC_500.OFFSET_tt_cng+1;
.CONST $M.AEC_500.OFFSET_RER_func $M.AEC_500.OFFSET_CNG_offset+1;
.CONST $M.AEC_500.OFFSET_dgStartPtr $M.AEC_500.OFFSET_RER_func+1;

.CONST $M.AEC_500.OFFSET_dg_control_Freq_Bins $M.AEC_500.OFFSET_dgStartPtr+1;

.CONST $M.AEC_500.OFFSET_AEC_COUPLING $M.AEC_500.OFFSET_dg_control_Freq_Bins+1;
.CONST $M.AEC_500.OFFSET_HD_L_AECgain $M.AEC_500.OFFSET_AEC_COUPLING+1;

.CONST $M.AEC_500.OFFSET_LPXFB_RERDT $M.AEC_500.OFFSET_HD_L_AECgain+1;

.CONST $M.AEC_500.STRUCT_SIZE $M.AEC_500.OFFSET_LPXFB_RERDT+1;






.CONST $M.FDNLP_500.OFFSET_VSM_HB 0;
.CONST $M.FDNLP_500.OFFSET_VSM_LB $M.FDNLP_500.OFFSET_VSM_HB+1;
.CONST $M.FDNLP_500.OFFSET_VSM_MAX_ATT $M.FDNLP_500.OFFSET_VSM_LB+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_HB $M.FDNLP_500.OFFSET_VSM_MAX_ATT+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_LB $M.FDNLP_500.OFFSET_FDNLP_HB+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_MB $M.FDNLP_500.OFFSET_FDNLP_LB+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_NBINS $M.FDNLP_500.OFFSET_FDNLP_MB+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_ATT $M.FDNLP_500.OFFSET_FDNLP_NBINS+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_ATT_THRESH $M.FDNLP_500.OFFSET_FDNLP_ATT+1;
.CONST $M.FDNLP_500.OFFSET_FDNLP_ECHO_THRESH $M.FDNLP_500.OFFSET_FDNLP_ATT_THRESH+1;
.CONST $M.FDNLP_500.STRUCT_SIZE $M.FDNLP_500.OFFSET_FDNLP_ECHO_THRESH+1;






.CONST $M.AEC_500_HF.OFFSET_D_REAL_PTR 0;


.CONST $M.AEC_500_HF.OFFSET_D_IMAG_PTR $M.AEC_500_HF.OFFSET_D_REAL_PTR+1;


.CONST $M.AEC_500_HF.OFFSET_NUM_FREQ_BINS $M.AEC_500_HF.OFFSET_D_IMAG_PTR+1;




.CONST $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN $M.AEC_500_HF.OFFSET_NUM_FREQ_BINS+1;



.CONST $M.AEC_500_HF.OFFSET_CALLSTATE_PTR $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN+1;


.CONST $M.AEC_500_HF.OFFSET_TIER2_THRESH $M.AEC_500_HF.OFFSET_CALLSTATE_PTR+1;


.CONST $M.AEC_500_HF.OFFSET_HC_TIER_STATE $M.AEC_500_HF.OFFSET_TIER2_THRESH+1;



.CONST $M.AEC_500_HF.OFFSET_PTR_RCV_DETECT $M.AEC_500_HF.OFFSET_HC_TIER_STATE+1;



.CONST $M.AEC_500_HF.OFFSET_PTR_TIER1_CONFIG $M.AEC_500_HF.OFFSET_PTR_RCV_DETECT+1;


.CONST $M.AEC_500_HF.OFFSET_PTR_TIER2_CONFIG $M.AEC_500_HF.OFFSET_PTR_TIER1_CONFIG+1;





.CONST $M.AEC_500_HF.HOWLING_CNTRL_FUNCPTR $M.AEC_500_HF.OFFSET_PTR_TIER2_CONFIG+1;




.CONST $M.AEC_500_HF.FDNLP_FUNCPTR $M.AEC_500_HF.HOWLING_CNTRL_FUNCPTR+1;




.CONST $M.AEC_500_HF.VSM_FUNCPTR $M.AEC_500_HF.FDNLP_FUNCPTR+1;





.CONST $M.AEC_500_HF.OFFSET_PTR_RatFE $M.AEC_500_HF.VSM_FUNCPTR+1;


.CONST $M.AEC_500_HF.OFFSET_PTR_SqGr $M.AEC_500_HF.OFFSET_PTR_RatFE+1;



.CONST $M.AEC_500_HF.OFFSET_SCRPTR_Attenuation $M.AEC_500_HF.OFFSET_PTR_SqGr+1;


.CONST $M.AEC_500_HF.OFFSET_SCRPTR_absGr $M.AEC_500_HF.OFFSET_SCRPTR_Attenuation+1;


.CONST $M.AEC_500_HF.OFFSET_SCRPTR_temp $M.AEC_500_HF.OFFSET_SCRPTR_absGr+1;


.CONST $M.AEC_500_HF.OFFSET_PTR_CUR_CONFIG $M.AEC_500_HF.OFFSET_SCRPTR_temp+1;
.CONST $M.AEC_500_HF.OFFSET_hd_ct_hold $M.AEC_500_HF.OFFSET_PTR_CUR_CONFIG+$M.FDNLP_500.STRUCT_SIZE;
.CONST $M.AEC_500_HF.OFFSET_hd_att $M.AEC_500_HF.OFFSET_hd_ct_hold+1;
.CONST $M.AEC_500_HF.OFFSET_G_vsm $M.AEC_500_HF.OFFSET_hd_att+1;
.CONST $M.AEC_500_HF.OFFSET_fdnlp_cont_test $M.AEC_500_HF.OFFSET_G_vsm+1;
.CONST $M.AEC_500_HF.OFFSET_mean_len $M.AEC_500_HF.OFFSET_fdnlp_cont_test+1;
.CONST $M.AEC_500_HF.OFFSET_Vad_ct_burst $M.AEC_500_HF.OFFSET_mean_len+1;
.CONST $M.AEC_500_HF.OFFSET_Vad_ct_hang $M.AEC_500_HF.OFFSET_Vad_ct_burst+1;

.CONST $M.AEC_500_HF.STRUCT_SIZE $M.AEC_500_HF.OFFSET_Vad_ct_hang+1;





.CONST $M.AEC_500.OFFSET_RER_VAR_THRESH $M.AEC_500.OFFSET_RER_SQGRDEV;


.CONST $M.AEC_500.L2TH_RERDT_OFF -20.0/128;
.CONST $M.AEC_500.RERDT_ADJUST 6.0/32;
.CONST $M.AEC_500.RERDT_POWER 1;





.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_E_REAL_PTR 0;

.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_E_IMAG_PTR $M.TWOMIC_AEC.OFFSET_FNLMS_E_REAL_PTR+1;

.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_EXP_PTR $M.TWOMIC_AEC.OFFSET_FNLMS_E_IMAG_PTR+1;

.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_REAL_PTR $M.TWOMIC_AEC.OFFSET_FNLMS_D_EXP_PTR+1;

.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_IMAG_PTR $M.TWOMIC_AEC.OFFSET_FNLMS_D_REAL_PTR+1;


.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt $M.TWOMIC_AEC.OFFSET_FNLMS_D_IMAG_PTR + 1;

.CONST $M.TWOMIC_AEC.OFFSET_PTR_MAIN_AEC $M.TWOMIC_AEC.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1 $M.TWOMIC_AEC.OFFSET_PTR_MAIN_AEC + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_Ga_real $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1 + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_Ga_imag $M.TWOMIC_AEC.OFFSET_PTR_Ga_real + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_BExp_Ga $M.TWOMIC_AEC.OFFSET_PTR_Ga_imag + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_real $M.TWOMIC_AEC.OFFSET_PTR_BExp_Ga + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_imag $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_real + 1;

.CONST $M.TWOMIC_AEC.STRUCT_SIZE $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_imag + 1;
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/filter_bank/filter_bank_library.h" 1
.linefile 47 "C:/ADK3.5/kalimba/lib_sets/sdk/include/filter_bank/filter_bank_library.h"
.CONST $FILTER_BANK_VERSION 0x030200;






   .CONST $M.filter_bank.Parameters.FRAME32 32;
   .CONST $M.filter_bank.Parameters.FRAME60 60;
   .CONST $M.filter_bank.Parameters.FRAME64 64;
   .CONST $M.filter_bank.Parameters.FRAME120 120;
   .CONST $M.filter_bank.Parameters.FRAME128 128;

   .CONST $M.filter_bank.Parameters.PROTO120 120;
   .CONST $M.filter_bank.Parameters.PROTO128 128;
   .CONST $M.filter_bank.Parameters.PROTO240 240;
   .CONST $M.filter_bank.Parameters.PROTO256 256;
   .CONST $M.filter_bank.Parameters.PROTO480 480;
   .CONST $M.filter_bank.Parameters.PROTO512 512;

   .CONST $M.filter_bank.Parameters.FFT128_SCALE 6;
   .CONST $M.filter_bank.Parameters.FFT256_SCALE 7;

   .CONST $M.filter_bank.Parameters.FFT128_NUM_BIN 65;
   .CONST $M.filter_bank.Parameters.FFT256_NUM_BIN 129;

   .CONST $M.filter_bank.Parameters.FFT128_BUFFLEN 64;
   .CONST $M.filter_bank.Parameters.FFT256_BUFFLEN 128;

   .CONST $M.filter_bank.Parameters.SPLIT_TABLELEN 63;
.linefile 91 "C:/ADK3.5/kalimba/lib_sets/sdk/include/filter_bank/filter_bank_library.h"
   .CONST $M.filter_bank.Parameters.Q_DAT_IN 0;
   .CONST $M.filter_bank.Parameters.Q_DAT_OUT 0;





   .CONST $M.filter_bank.Parameters.FFT_EXTRA_SCALE 0;
   .CONST $M.filter_bank.Parameters.IFFT_EXTRA_SCALE 0;





   .CONST $M.filter_bank.CONST.MIN24 0x800000;





   .CONST $M.filter_bank.config.FRAME 0;
   .CONST $M.filter_bank.config.PROTO 1;
   .CONST $M.filter_bank.config.ZEROPADDED_PROTO 2;
   .CONST $M.filter_bank.config.FFT_SCALE 3;
   .CONST $M.filter_bank.config.PTR_PROTO 4;
   .CONST $M.filter_bank.config.STRUCT_SIZE 5;
.linefile 132 "C:/ADK3.5/kalimba/lib_sets/sdk/include/filter_bank/filter_bank_library.h"
   .CONST $M.filter_bank.fft.NUM_POINTS_FIELD 0;



   .CONST $M.filter_bank.fft.REAL_ADDR_FIELD 1;



   .CONST $M.filter_bank.fft.IMAG_ADDR_FIELD 2;



   .CONST $M.filter_bank.fft.CBUF_ADDR_FIELD 3;


   .CONST $M.filter_bank.fft.CBUF_BITREV_ADDR_FIELD 4;


   .CONST $M.filter_bank.fft.PTR_FFTSPLIT 5;


   .CONST $M.filter_bank.fft.FFT_EXTRA_SCALE 6;


   .CONST $M.filter_bank.fft.IFFT_EXTRA_SCALE 7;


   .CONST $M.filter_bank.fft.Q_DAT_IN 8;


   .CONST $M.filter_bank.fft.Q_DAT_OUT 9;

   .CONST $M.filter_bank.fft.STRUC_SIZE 10;
.linefile 182 "C:/ADK3.5/kalimba/lib_sets/sdk/include/filter_bank/filter_bank_library.h"
   .CONST $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT 0;


   .CONST $M.filter_bank.Parameters.OFFSET_PTR_FRAME 1;


   .CONST $M.filter_bank.Parameters.OFFSET_PTR_HISTORY 2;


   .CONST $M.filter_bank.Parameters.OFFSET_BEXP 3;


   .CONST $M.filter_bank.Parameters.OFFSET_PTR_BEXP 3;


   .CONST $M.filter_bank.Parameters.OFFSET_PTR_FFTREAL 4;


   .CONST $M.filter_bank.Parameters.OFFSET_PTR_FFTIMAG 5;


   .CONST $M.filter_bank.Parameters.OFFSET_DELAY_PTR 6;


   .CONST $M.filter_bank.Parameters.OFFSET_DELAY_BUF_BASE 7;


   .CONST $M.filter_bank.Parameters.OFFSET_DELAY_BUF_PTR 8;


   .CONST $M.filter_bank.Parameters.OFFSET_DELAY_BUF_LEN 9;

   .CONST $M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE 10;
.linefile 232 "C:/ADK3.5/kalimba/lib_sets/sdk/include/filter_bank/filter_bank_library.h"
   .CONST $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT 0;



   .CONST $M.filter_bank.Parameters.OFFSET_CH1_PTR_FRAME 1;



   .CONST $M.filter_bank.Parameters.OFFSET_CH2_PTR_FRAME 2;


   .CONST $M.filter_bank.Parameters.OFFSET_CH1_PTR_HISTORY 3;


   .CONST $M.filter_bank.Parameters.OFFSET_CH2_PTR_HISTORY 4;


   .CONST $M.filter_bank.Parameters.OFFSET_CH1_BEXP 5;


   .CONST $M.filter_bank.Parameters.OFFSET_CH1_PTR_BEXP 5;


   .CONST $M.filter_bank.Parameters.OFFSET_CH2_BEXP 6;


   .CONST $M.filter_bank.Parameters.OFFSET_CH2_PTR_BEXP 6;



   .CONST $M.filter_bank.Parameters.OFFSET_CH1_PTR_FFTREAL 7;



   .CONST $M.filter_bank.Parameters.OFFSET_CH1_PTR_FFTIMAG 8;



   .CONST $M.filter_bank.Parameters.OFFSET_CH2_PTR_FFTREAL 9;



   .CONST $M.filter_bank.Parameters.OFFSET_CH2_PTR_FFTIMAG 10;



   .CONST $M.filter_bank.Parameters.OFFSET_CH2_DELAY_PTR 11;


   .CONST $M.filter_bank.Parameters.OFFSET_CH2_DELAY_BASE 12;



   .CONST $M.filter_bank.Parameters.OFFSET_CH2_DELAY_BUF_PTR 13;


   .CONST $M.filter_bank.Parameters.OFFSET_CH2_DELAY_BUF_LEN 14;


   .CONST $M.filter_bank.Parameters.TWO_CHNL_BLOCK_SIZE 15;
.linefile 19 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/oms270/harmonicity.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/oms270/harmonicity.h"
.CONST $harmonicity.WINDOW_LENGTH 30;
.CONST $harmonicity.DELAY_LENGTH 27;

.CONST $harmonicity.nb.FRAME_SIZE 60;
.CONST $harmonicity.nb.DELAY_START 53;
.CONST $harmonicity.nb.DECIMATION 2;

.CONST $harmonicity.wb.FRAME_SIZE 120;
.CONST $harmonicity.wb.DELAY_START 107;
.CONST $harmonicity.wb.DECIMATION 4;





.CONST $harmonicity.MODE_FIELD 0;
.CONST $harmonicity.INP_X_FIELD 1;
.CONST $harmonicity.FFT_WINDOW_SIZE_FIELD 2;
.CONST $harmonicity.FLAG_ON_FIELD 3;
.CONST $harmonicity.HARM_VALUE_FIELD 4;
.CONST $harmonicity.AMDF_MEM_START_FIELD 5;
.CONST $harmonicity.STRUC_SIZE ($harmonicity.AMDF_MEM_START_FIELD + $harmonicity.DELAY_LENGTH);





.CONST $harmonicity.mode.FRAME_SIZE 0;
.CONST $harmonicity.mode.DELAY_START 1;
.CONST $harmonicity.mode.DECIMATION 2;
.linefile 20 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/oms270/oms270_library.h" 1
.linefile 27 "C:/ADK3.5/kalimba/lib_sets/sdk/include/oms270/oms270_library.h"
.CONST $oms270.MAX_MIN_SEARCH_LENGTH 68;
.CONST $oms270.PBP.DIM_NB 25;
.CONST $oms270.PBP.DIM_WB 30;
.CONST $oms270.PBP.NUM_LINEAR_BAND 15;
.CONST $oms270.PBP.MS_BAND 2;
.CONST $oms270.PBP.NOISE_THRESHOLD 0.8;

.CONST $M.oms270.QUE_LENGTH ($oms270.MAX_MIN_SEARCH_LENGTH * $oms270.PBP.MS_BAND);
.CONST $M.oms270.narrow_band.STATE_LENGTH ($oms270.PBP.DIM_NB * 4 + 2 * $oms270.PBP.MS_BAND);
.CONST $M.oms270.wide_band.STATE_LENGTH ($oms270.PBP.DIM_WB * 4 + 2 * $oms270.PBP.MS_BAND);
.CONST $M.oms270.narrow_band.SCRATCH_LENGTH ($oms270.PBP.DIM_NB + 2 * ( 65-2-$oms270.PBP.NUM_LINEAR_BAND));
.CONST $M.oms270.wide_band.SCRATCH_LENGTH ($oms270.PBP.DIM_WB + 2 * (129-2-$oms270.PBP.NUM_LINEAR_BAND));
.CONST $M.oms270.NOISE_THRESHOLD ($oms270.PBP.NOISE_THRESHOLD);




.CONST $oms270.linear.DIM 65;
.CONST $oms270.linear.narrow_band.MS_BAND 2;
.CONST $oms270.linear.wide_band.MS_BAND 3;
.CONST $oms270.linear.NOISE_THRESHOLD 0.9;

.CONST $oms270.linear.narrow_band.QUE_LENGTH ($M.oms270.QUE_LENGTH);
.CONST $oms270.linear.wide_band.QUE_LENGTH ($oms270.MAX_MIN_SEARCH_LENGTH * $oms270.linear.wide_band.MS_BAND);
.CONST $oms270.linear.narrow_band.STATE_LENGTH ($oms270.linear.DIM * 2 + 2 * $oms270.linear.narrow_band.MS_BAND);
.CONST $oms270.linear.wide_band.STATE_LENGTH ($oms270.linear.DIM * 2 + 2 * $oms270.linear.wide_band.MS_BAND);
.CONST $oms270.linear.SCRATCH_LENGTH ($oms270.linear.DIM * 4 + $oms270.linear.wide_band.MS_BAND);




.CONST $dms100.DIM 65;
.CONST $dms100.MIN_SEARCH_LENGTH 34;
.CONST $dms100.MS_BAND 8;
.CONST $dms100.NOISE_THRESHOLD 0.8;

.CONST $dms100.QUE_LENGTH ($dms100.MIN_SEARCH_LENGTH * $dms100.MS_BAND);
.CONST $dms100.STATE_LENGTH ($dms100.DIM * 6 + $dms100.MS_BAND * 2);
.CONST $dms100.SCRATCH_LENGTH ($dms100.DIM * 4 + $dms100.MS_BAND);
.linefile 83 "C:/ADK3.5/kalimba/lib_sets/sdk/include/oms270/oms270_library.h"
.CONST $M.oms270.PTR_MODE_FIELD 0;


.CONST $M.oms270.CONTROL_WORD_FIELD $M.oms270.PTR_MODE_FIELD + 1;


.CONST $M.oms270.BYPASS_BIT_MASK_FIELD $M.oms270.CONTROL_WORD_FIELD + 1;


.CONST $M.oms270.MIN_SEARCH_ON_FIELD $M.oms270.BYPASS_BIT_MASK_FIELD + 1;


.CONST $M.oms270.HARM_ON_FIELD $M.oms270.MIN_SEARCH_ON_FIELD + 1;


.CONST $M.oms270.MMSE_LSA_ON_FIELD $M.oms270.HARM_ON_FIELD + 1;


.CONST $M.oms270.FFT_WINDOW_SIZE_FIELD $M.oms270.MMSE_LSA_ON_FIELD + 1;


.CONST $M.oms270.PTR_INP_X_FIELD $M.oms270.FFT_WINDOW_SIZE_FIELD + 1;


.CONST $M.oms270.PTR_X_REAL_FIELD $M.oms270.PTR_INP_X_FIELD + 1;


.CONST $M.oms270.PTR_X_IMAG_FIELD $M.oms270.PTR_X_REAL_FIELD + 1;


.CONST $M.oms270.PTR_BEXP_X_FIELD $M.oms270.PTR_X_IMAG_FIELD + 1;


.CONST $M.oms270.PTR_Y_REAL_FIELD $M.oms270.PTR_BEXP_X_FIELD + 1;


.CONST $M.oms270.PTR_Y_IMAG_FIELD $M.oms270.PTR_Y_REAL_FIELD + 1;


.CONST $M.oms270.INITIAL_POWER_FIELD $M.oms270.PTR_Y_IMAG_FIELD + 1;


.CONST $M.oms270.LPX_QUEUE_START_FIELD $M.oms270.INITIAL_POWER_FIELD + 1;



.CONST $M.oms270.PTR_G_FIELD $M.oms270.LPX_QUEUE_START_FIELD + 1;


.CONST $M.oms270.PTR_LPXNZ_FIELD $M.oms270.PTR_G_FIELD + 1;


.CONST $M.oms270.PTR_STATE_FIELD $M.oms270.PTR_LPXNZ_FIELD + 1;


.CONST $M.oms270.PTR_SCRATCH_FIELD $M.oms270.PTR_STATE_FIELD + 1;


.CONST $M.oms270.ALFANZ_FIELD $M.oms270.PTR_SCRATCH_FIELD + 1;


.CONST $M.oms270.LALFAS_FIELD $M.oms270.ALFANZ_FIELD + 1;


.CONST $M.oms270.LALFAS1_FIELD $M.oms270.LALFAS_FIELD + 1;


.CONST $M.oms270.HARM_THRESH_FIELD $M.oms270.LALFAS1_FIELD + 1;


.CONST $M.oms270.VAD_THRESH_FIELD $M.oms270.HARM_THRESH_FIELD + 1;


.CONST $M.oms270.AGRESSIVENESS_FIELD $M.oms270.VAD_THRESH_FIELD + 1;


.CONST $M.oms270.PTR_TONE_FLAG_FIELD $M.oms270.AGRESSIVENESS_FIELD + 1;






.CONST $dms100.Y_FIELD 1 + $M.oms270.PTR_TONE_FLAG_FIELD;



.CONST $dms100.X_FIELD 1 + $dms100.Y_FIELD;



.CONST $dms100.D_FIELD 1 + $dms100.X_FIELD;



.CONST $dms100.PARAM_FIELD 1 + $dms100.D_FIELD;




.CONST $dms100.PTR_POWR_ADJUST_FIELD 1 + $dms100.PARAM_FIELD;



.CONST $dms100.PTR_DMS_MODE_FIELD 1 + $dms100.PTR_POWR_ADJUST_FIELD;



.CONST $dms100.INTERNAL_FIELD 1 + $dms100.PTR_DMS_MODE_FIELD;


.CONST $dms100.SPP_FIELD 0 + $dms100.INTERNAL_FIELD;
.CONST $dms100.LPDS_FIELD 1 + $dms100.SPP_FIELD;
.CONST $dms100.LPN_FIELD 1 + $dms100.LPDS_FIELD;
.CONST $dms100.VAD_T_LIKE_FIELD 1 + $dms100.LPN_FIELD;
.CONST $dms100.SNR_FIELD 1 + $dms100.VAD_T_LIKE_FIELD;


.CONST $dms100.MASTER_DMS_MODE_FIELD 1 + $dms100.SNR_FIELD;
.CONST $dms100.GSCHEME_FIELD 1 + $dms100.MASTER_DMS_MODE_FIELD;
.CONST $dms100.BYPASS_SPP_FIELD 1 + $dms100.GSCHEME_FIELD;
.CONST $dms100.BYPASS_GSMOOTH_FIELD 1 + $dms100.BYPASS_SPP_FIELD;
.CONST $dms100.BYPASS_NFLOOR_FIELD 1 + $dms100.BYPASS_GSMOOTH_FIELD;
.CONST $dms100.BYPASS_NLIFT_FIELD 1 + $dms100.BYPASS_NFLOOR_FIELD;


.CONST $dms100.VAD_VOICED_FIELD 1 + $dms100.BYPASS_NLIFT_FIELD;
.CONST $dms100.VAD_COUNT_FIELD 1 + $dms100.VAD_VOICED_FIELD;
.CONST $dms100.VAD_LIKE_MEAN_FIELD 1 + $dms100.VAD_COUNT_FIELD;
.CONST $dms100.DMS_MODE_FIELD 1 + $dms100.VAD_LIKE_MEAN_FIELD;


.CONST $M.oms270.DMS_COMMON_FIELD 1 + $dms100.DMS_MODE_FIELD;

.CONST $M.oms270.FUNC_MMS_LPXS_FIELD 0 + $M.oms270.DMS_COMMON_FIELD;
.CONST $M.oms270.FUNC_MMS_PROC_FIELD 1 + $M.oms270.DMS_COMMON_FIELD;
.CONST $M.oms270.PTR_HARM_VALUE_FIELD 2 + $M.oms270.DMS_COMMON_FIELD;
.CONST $M.oms270.LTILT_FIELD $M.oms270.PTR_HARM_VALUE_FIELD + 1;
.CONST $M.oms270.VOICED_FIELD $M.oms270.LTILT_FIELD + 1;
.CONST $M.oms270.MIN_SEARCH_COUNT_FIELD $M.oms270.VOICED_FIELD + 1;
.CONST $M.oms270.MIN_SEARCH_LENGTH_FIELD $M.oms270.MIN_SEARCH_COUNT_FIELD + 1;
.CONST $M.oms270.PTR_LPXS_FIELD $M.oms270.MIN_SEARCH_LENGTH_FIELD + 1;
.CONST $M.oms270.PTR_LPY_FIELD $M.oms270.PTR_LPXS_FIELD + 1;
.CONST $M.oms270.VOICED_COUNTER_FIELD $M.oms270.PTR_LPY_FIELD + 1;
.CONST $M.oms270.PTR_LPX_MIN_FIELD $M.oms270.VOICED_COUNTER_FIELD + 1;

.CONST $M.oms270.WIND_FIELD $M.oms270.PTR_LPX_MIN_FIELD + 1;
.CONST $M.oms270.WNR_OBJ_FIELD $M.oms270.WIND_FIELD + 1;
.CONST $M.oms270.FUNC_WIND_DETECT_FIELD $M.oms270.WNR_OBJ_FIELD + 1;
.CONST $M.oms270.FUNC_WIND_REDUCTION_FIELD $M.oms270.FUNC_WIND_DETECT_FIELD + 1;
.CONST $M.oms270.INITIALISED_FIELD $M.oms270.FUNC_WIND_REDUCTION_FIELD + 1;
.CONST $M.oms270.LIKE_MEAN_FIELD $M.oms270.INITIALISED_FIELD + 1;
.CONST $M.oms270.TEMP_FIELD $M.oms270.LIKE_MEAN_FIELD + 1;


.CONST $M.oms270.G_G_FIELD $M.oms270.TEMP_FIELD + 1;
.CONST $M.oms270.MS_LPN_FIELD $M.oms270.G_G_FIELD + 1;
.CONST $M.oms270.PTR_LPX_QUEUE_FIELD $M.oms270.MS_LPN_FIELD + 1;
.CONST $M.oms270.PTR_LPN_FIELD $M.oms270.PTR_LPX_QUEUE_FIELD + 1;


.CONST $M.oms270.SCRATCH_LPXT_FIELD $M.oms270.PTR_LPN_FIELD + 1;
.CONST $M.oms270.SCRATCH_LIKE_FIELD $M.oms270.SCRATCH_LPXT_FIELD + 1;
.CONST $M.oms270.SCRATCH_NZLIFT_FIELD $M.oms270.SCRATCH_LIKE_FIELD + 1;
.CONST $M.oms270.SCRATCH_LPNZLIFT_FIELD $M.oms270.SCRATCH_NZLIFT_FIELD + 1;
.CONST $M.oms270.SCRATCH_LTILT_FIELD $M.oms270.SCRATCH_LPNZLIFT_FIELD + 1;


.CONST $M.oms270.OMS_MODE_FLAG_FIELD $M.oms270.SCRATCH_LTILT_FIELD + 1;


.CONST $M.oms270.HARM_START_FIELD $M.oms270.OMS_MODE_FLAG_FIELD + 1;
.CONST $M.oms270.HAM_MODE_FIELD $M.oms270.HARM_START_FIELD + $harmonicity.MODE_FIELD;
.CONST $M.oms270.HAM_INP_X_FIELD $M.oms270.HARM_START_FIELD + $harmonicity.INP_X_FIELD;
.CONST $M.oms270.HAM_FFT_WINDOW_SIZE_FIELD $M.oms270.HARM_START_FIELD + $harmonicity.FFT_WINDOW_SIZE_FIELD;
.CONST $M.oms270.HAM_FLAG_ON_FIELD $M.oms270.HARM_START_FIELD + $harmonicity.FLAG_ON_FIELD;
.CONST $M.oms270.HARM_VALUE_FIELD $M.oms270.HARM_START_FIELD + $harmonicity.HARM_VALUE_FIELD;


.CONST $M.oms270.STRUC_SIZE $M.oms270.HARM_START_FIELD + $harmonicity.STRUC_SIZE;
.CONST $dms100.STRUC_SIZE $M.oms270.STRUC_SIZE;
.linefile 276 "C:/ADK3.5/kalimba/lib_sets/sdk/include/oms270/oms270_library.h"
.CONST $M.oms270.wnr.FUNC_WNR_INIT_FIELD 0;


.CONST $M.oms270.wnr.PTR_WNR_PARAM_FIELD 1;


.CONST $M.oms270.wnr.PTR_RCVVAD_FLAG_FIELD 2;


.CONST $M.oms270.wnr.PTR_SNDVAD_FLAG_FIELD 3;


.CONST $M.oms270.wnr.SND_VAD_COUNT_FIELD 4;
.CONST $M.oms270.wnr.HOLD_FIELD 5;
.CONST $M.oms270.wnr.YWEI_FIELD 6;
.CONST $M.oms270.wnr.POWER_THRES_FIELD 7;
.CONST $M.oms270.wnr.POWER_LEVEL_FIELD 8;
.CONST $M.oms270.wnr.COUNT_FIELD 9;

.CONST $M.oms270.wnr.HIGH_BIN_FIELD 10;
.CONST $M.oms270.wnr.LOW_BIN_FIELD 11;
.CONST $M.oms270.wnr.ROLLOFF_IDX_FIELD 12;
.CONST $M.oms270.wnr.STRUC_SIZE 13;
.linefile 310 "C:/ADK3.5/kalimba/lib_sets/sdk/include/oms270/oms270_library.h"
.CONST $M.oms270.param.WNR_AGRESSIVENESS_FIELD 0;


.CONST $M.oms270.param.WNR_POWER_THRESHOLD_FIELD 1;


.CONST $M.oms270.param.WNR_HOLD_FIELD 2;
.linefile 328 "C:/ADK3.5/kalimba/lib_sets/sdk/include/oms270/oms270_library.h"
.CONST $dms100.param.AGRESSIVENESS_FIELD 0;



.CONST $dms100.param.RESIDUAL_NFLOOR_FIELD 1;
.linefile 21 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/ndvc100/ndvc100_library.h" 1
.linefile 38 "C:/ADK3.5/kalimba/lib_sets/sdk/include/ndvc100/ndvc100_library.h"
   .CONST $NDVC_ALG1_0_0_VERSION 0x020000;


   .CONST $M.NDVC_Alg1_0_0.MAX_STEPS 8;
.linefile 61 "C:/ADK3.5/kalimba/lib_sets/sdk/include/ndvc100/ndvc100_library.h"
.CONST $M.NDVC_Alg1_0_0.PARAMETERS.OFFSET_NDVC_HYSTERESIS 0;


.CONST $M.NDVC_Alg1_0_0.PARAMETERS.OFFSET_NDVC_ATK_TC 1;


.CONST $M.NDVC_Alg1_0_0.PARAMETERS.OFFSET_NDVC_DEC_TC 2;


.CONST $M.NDVC_Alg1_0_0.PARAMETERS.OFFSET_NDVC_NUMVOLSTEPS 3;


.CONST $M.NDVC_Alg1_0_0.PARAMETERS.OFFSET_NDVC_MAXNOISELVL 4;


.CONST $M.NDVC_Alg1_0_0.PARAMETERS.OFFSET_NDVC_MINNOISELVL 5;


.CONST $M.NDVC_Alg1_0_0.PARAMETERS.OFFSET_NDVC_LB 6;


.CONST $M.NDVC_Alg1_0_0.PARAMETERS.OFFSET_NDVC_HB 7;


.CONST $M.NDVC_Alg1_0_0.PARAMETERS.BLOCKSIZE 8;







.CONST $M.NDVC_Alg1_0_0.OFFSET_CONTROL_WORD 0;


.CONST $M.NDVC_Alg1_0_0.OFFSET_BITMASK_BYPASS 1;


.CONST $M.NDVC_Alg1_0_0.OFFSET_MAXSTEPS 2;


.CONST $M.NDVC_Alg1_0_0.OFFSET_PTR_LPDNZ 3;


.CONST $M.NDVC_Alg1_0_0.OFFSET_PTR_PARAMS 4;


.CONST $M.NDVC_Alg1_0_0.OFFSET_CURVOLLEVEL 5;


.CONST $M.NDVC_Alg1_0_0.OFFSET_FILTSUMLPDNZ 6;


.CONST $M.NDVC_Alg1_0_0.OFFSET_NOISE_DELTA 7;


.CONST $M.NDVC_Alg1_0_0.OFFSET_INV_NUMBIN 8;


.CONST $M.NDVC_Alg1_0_0.OFFSET_NOISELVLTBL 9;


.CONST $M.NDVC_Alg1_0_0.BLOCK_SIZE 9;
.linefile 22 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/agc400/agc400_library.h" 1
.linefile 36 "C:/ADK3.5/kalimba/lib_sets/sdk/include/agc400/agc400_library.h"
.CONST $AGC400_VERSION 0x010000;
.linefile 50 "C:/ADK3.5/kalimba/lib_sets/sdk/include/agc400/agc400_library.h"
.CONST $M.agc400.Parameter.OFFSET_INITIAL_GAIN_FIELD 0;


.CONST $M.agc400.Parameter.OFFSET_AGC_TARGET_FIELD 1;


.CONST $M.agc400.Parameter.OFFSET_ATTACK_TC_FIELD 2;


.CONST $M.agc400.Parameter.OFFSET_DECAY_TC_FIELD 3;


.CONST $M.agc400.Parameter.OFFSET_ALPHA_A_90_FIELD 4;


.CONST $M.agc400.Parameter.OFFSET_ALPHA_D_90_FIELD 5;


.CONST $M.agc400.Parameter.OFFSET_G_MAX_FIELD 6;


.CONST $M.agc400.Parameter.OFFSET_START_COMP_FIELD 7;


.CONST $M.agc400.Parameter.OFFSET_COMP_FIELD 8;


.CONST $M.agc400.Parameter.OFFSET_INPUT_THRESHOLD_FIELD 9;


.CONST $M.agc400.Parameter.OFFSET_ATTACK_SPEED_FIELD 10;


.CONST $M.agc400.Parameter.OFFSET_ADAPT_THRESHOLD1_FIELD 11;


.CONST $M.agc400.Parameter.OFFSET_ADAPT_THRESHOLD2_FIELD 12;


.CONST $M.agc400.Parameter.OFFSET_G_MIN_FIELD 13;


.CONST $M.agc400.Parameter.STRUC_SIZE 14;







.CONST $M.agc400.OFFSET_SYS_CON_WORD_FIELD 0;


.CONST $M.agc400.OFFSET_BYPASS_BIT_MASK_FIELD 1;


.CONST $M.agc400.OFFSET_BYPASS_PERSIST_FIELD 2;


.CONST $M.agc400.OFFSET_PARAM_PTR_FIELD 3;


.CONST $M.agc400.OFFSET_PTR_INPUT_FIELD 4;


.CONST $M.agc400.OFFSET_PTR_OUTPUT_FIELD 5;


.CONST $M.agc400.OFFSET_PTR_VAD_VALUE_FIELD 6;


.CONST $M.agc400.OFFSET_HARD_LIMIT_FIELD 7;


.CONST $M.agc400.OFFSET_PTR_TONE_FLAG_FIELD 8;


.CONST $M.agc400.OFFSET_INPUT_LEVEL_FIELD 9;


.CONST $M.agc400.OFFSET_INPUT_LEVEL_MIN_FIELD 10;


.CONST $M.agc400.OFFSET_ONE_M_ATTACK_TC_FIELD 11;


.CONST $M.agc400.OFFSET_ONE_M_DECAY_TC_FIELD 12;


.CONST $M.agc400.OFFSET_ONE_M_ALPHA_A_90_FIELD 13;


.CONST $M.agc400.OFFSET_ONE_M_ALPHA_D_90_FIELD 14;


.CONST $M.agc400.OFFSET_G_MIN_FIELD 15;


.CONST $M.agc400.OFFSET_G_FIELD 16;


.CONST $M.agc400.OFFSET_G_REAL_FIELD 17;


.CONST $M.agc400.OFFSET_ONE_M_COMP_FIELD 18;


.CONST $M.agc400.OFFSET_PWR_SCALE_FIELD 19;


.CONST $M.agc400.OFFSET_FRAME_THRESHOLD_FIELD 20;


.CONST $M.agc400.OFFSET_FRAME_COUNTER_FIELD 21;


.CONST $M.agc400.OFFSET_PERSISTED_GAIN_FIELD 22;


.CONST $M.agc400.STRUC_SIZE 23;
.linefile 23 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/vad400/vad400_library.h" 1
.linefile 20 "C:/ADK3.5/kalimba/lib_sets/sdk/include/vad400/vad400_library.h"
.CONST $VAD400_VERSION 0x010000;
.linefile 33 "C:/ADK3.5/kalimba/lib_sets/sdk/include/vad400/vad400_library.h"
.CONST $M.vad400.Parameter.ATTACK_TC_FIELD 0;


.CONST $M.vad400.Parameter.DECAY_TC_FIELD 1;


.CONST $M.vad400.Parameter.ENVELOPE_TC_FIELD 2;


.CONST $M.vad400.Parameter.INIT_FRAME_THRESH_FIELD 3;


.CONST $M.vad400.Parameter.RATIO_FIELD 4;


.CONST $M.vad400.Parameter.MIN_SIGNAL_FIELD 5;


.CONST $M.vad400.Parameter.MIN_MAX_ENVELOPE_FIELD 6;


.CONST $M.vad400.Parameter.DELTA_THRESHOLD_FIELD 7;


.CONST $M.vad400.Parameter.COUNT_THRESHOLD_FIELD 8;


.CONST $M.vad400.Parameter.OBJECT_SIZE_FIELD 9;
.linefile 70 "C:/ADK3.5/kalimba/lib_sets/sdk/include/vad400/vad400_library.h"
.CONST $M.vad400.INPUT_PTR_FIELD 0;


.CONST $M.vad400.PARAM_PTR_FIELD 1;


.CONST $M.vad400.E_FILTER_FIELD 2;


.CONST $M.vad400.E_FILTER_MAX_FIELD 3;


.CONST $M.vad400.E_FILTER_MIN_FIELD 4;


.CONST $M.vad400.COUNTER_DELTA_FIELD 5;


.CONST $M.vad400.COUNTER_FIELD 6;


.CONST $M.vad400.FLAG_FIELD 7;


.CONST $M.vad400.OBJECT_SIZE_FIELD 8;
.linefile 24 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/AdapEq/AdapEq_library.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/AdapEq/AdapEq_library.h"
.CONST $ADAPEQ_VERSION 0x01000A;



.CONST $M.AdapEq.Num_AEQ_Bands 3;
.CONST $M.AdapEq.Bands_Buffer_Length ($M.AdapEq.Num_AEQ_Bands * 2);
.CONST $M.AdapEq.Scratch_Length 65;
.linefile 26 "C:/ADK3.5/kalimba/lib_sets/sdk/include/AdapEq/AdapEq_library.h"
.CONST $M.AdapEq.CONTROL_WORD_FIELD 0;


.CONST $M.AdapEq.BYPASS_BIT_MASK_FIELD $M.AdapEq.CONTROL_WORD_FIELD + 1;


.CONST $M.AdapEq.BEX_BIT_MASK_FIELD $M.AdapEq.BYPASS_BIT_MASK_FIELD + 1;


.CONST $M.AdapEq.NUM_FREQ_BINS $M.AdapEq.BEX_BIT_MASK_FIELD + 1;


.CONST $M.AdapEq.BEX_NOISE_LVL_FLAGS $M.AdapEq.NUM_FREQ_BINS + 1;


.CONST $M.AdapEq.PTR_X_REAL_FIELD $M.AdapEq.BEX_NOISE_LVL_FLAGS + 1;


.CONST $M.AdapEq.PTR_X_IMAG_FIELD $M.AdapEq.PTR_X_REAL_FIELD + 1;


.CONST $M.AdapEq.PTR_BEXP_X_FIELD $M.AdapEq.PTR_X_IMAG_FIELD + 1;


.CONST $M.AdapEq.PTR_Z_REAL_FIELD $M.AdapEq.PTR_BEXP_X_FIELD + 1;


.CONST $M.AdapEq.PTR_Z_IMAG_FIELD $M.AdapEq.PTR_Z_REAL_FIELD + 1;


.CONST $M.AdapEq.LOW_INDEX_FIELD $M.AdapEq.PTR_Z_IMAG_FIELD + 1;


.CONST $M.AdapEq.LOW_BW_FIELD $M.AdapEq.LOW_INDEX_FIELD + 1;


.CONST $M.AdapEq.LOG2_LOW_INDEX_DIF_FIELD $M.AdapEq.LOW_BW_FIELD + 1;


.CONST $M.AdapEq.MID_BW_FIELD $M.AdapEq.LOG2_LOW_INDEX_DIF_FIELD + 1;


.CONST $M.AdapEq.LOG2_MID_INDEX_DIF_FIELD $M.AdapEq.MID_BW_FIELD + 1;


.CONST $M.AdapEq.HIGH_BW_FIELD $M.AdapEq.LOG2_MID_INDEX_DIF_FIELD + 1;


.CONST $M.AdapEq.LOG2_HIGH_INDEX_DIF_FIELD $M.AdapEq.HIGH_BW_FIELD + 1;


.CONST $M.AdapEq.AEQ_EQ_COUNTER_FIELD $M.AdapEq.LOG2_HIGH_INDEX_DIF_FIELD + 1;


.CONST $M.AdapEq.AEQ_EQ_INIT_FRAME_FIELD $M.AdapEq.AEQ_EQ_COUNTER_FIELD + 1;

.CONST $M.AdapEq.AEQ_GAIN_LOW_FIELD $M.AdapEq.AEQ_EQ_INIT_FRAME_FIELD + 1;

.CONST $M.AdapEq.AEQ_GAIN_HIGH_FIELD $M.AdapEq.AEQ_GAIN_LOW_FIELD + 1;



.CONST $M.AdapEq.PTR_VAD_AGC_FIELD $M.AdapEq.AEQ_GAIN_HIGH_FIELD + 1;


.CONST $M.AdapEq.ALFA_A_FIELD $M.AdapEq.PTR_VAD_AGC_FIELD + 1;


.CONST $M.AdapEq.ONE_MINUS_ALFA_A_FIELD $M.AdapEq.ALFA_A_FIELD + 1;


.CONST $M.AdapEq.ALFA_D_FIELD $M.AdapEq.ONE_MINUS_ALFA_A_FIELD + 1;


.CONST $M.AdapEq.ONE_MINUS_ALFA_D_FIELD $M.AdapEq.ALFA_D_FIELD + 1;


.CONST $M.AdapEq.ALFA_ENV_FIELD $M.AdapEq.ONE_MINUS_ALFA_D_FIELD + 1;


.CONST $M.AdapEq.ONE_MINUS_ALFA_ENV_FIELD $M.AdapEq.ALFA_ENV_FIELD + 1;


.CONST $M.AdapEq.PTR_AEQ_BAND_PX_FIELD $M.AdapEq.ONE_MINUS_ALFA_ENV_FIELD + 1;


.CONST $M.AdapEq.STATE_FIELD $M.AdapEq.PTR_AEQ_BAND_PX_FIELD + 1;


.CONST $M.AdapEq.PTR_VOL_STEP_UP_FIELD $M.AdapEq.STATE_FIELD + 1;


.CONST $M.AdapEq.VOL_STEP_UP_TH1_FIELD $M.AdapEq.PTR_VOL_STEP_UP_FIELD + 1;


.CONST $M.AdapEq.VOL_STEP_UP_TH2_FIELD $M.AdapEq.VOL_STEP_UP_TH1_FIELD + 1;


.CONST $M.AdapEq.PTR_GOAL_LOW_FIELD $M.AdapEq.VOL_STEP_UP_TH2_FIELD + 1;


.CONST $M.AdapEq.PTR_GOAL_HIGH_FIELD $M.AdapEq.PTR_GOAL_LOW_FIELD + 1;


.CONST $M.AdapEq.PTR_BEX_ATT_TOTAL_FIELD $M.AdapEq.PTR_GOAL_HIGH_FIELD + 1;


.CONST $M.AdapEq.PTR_BEX_GOAL_HIGH2_FIELD $M.AdapEq.PTR_BEX_ATT_TOTAL_FIELD + 1;


.CONST $M.AdapEq.BEX_PASS_LOW_FIELD $M.AdapEq.PTR_BEX_GOAL_HIGH2_FIELD + 1;


.CONST $M.AdapEq.BEX_PASS_HIGH_FIELD $M.AdapEq.BEX_PASS_LOW_FIELD + 1;


.CONST $M.AdapEq.MID1_INDEX_FIELD $M.AdapEq.BEX_PASS_HIGH_FIELD + 1;


.CONST $M.AdapEq.MID2_INDEX_FIELD $M.AdapEq.MID1_INDEX_FIELD + 1;


.CONST $M.AdapEq.HIGH_INDEX_FIELD $M.AdapEq.MID2_INDEX_FIELD + 1;


.CONST $M.AdapEq.INV_AEQ_PASS_LOW_FIELD $M.AdapEq.HIGH_INDEX_FIELD + 1;


.CONST $M.AdapEq.INV_AEQ_PASS_HIGH_FIELD $M.AdapEq.INV_AEQ_PASS_LOW_FIELD + 1;


.CONST $M.AdapEq.AEQ_PASS_LOW_FIELD $M.AdapEq.INV_AEQ_PASS_HIGH_FIELD + 1;


.CONST $M.AdapEq.AEQ_PASS_HIGH_FIELD $M.AdapEq.AEQ_PASS_LOW_FIELD + 1;




.CONST $M.AdapEq.AEQ_POWER_TH_FIELD $M.AdapEq.AEQ_PASS_HIGH_FIELD + 1;


.CONST $M.AdapEq.AEQ_TONE_POWER_FIELD $M.AdapEq.AEQ_POWER_TH_FIELD + 1;


.CONST $M.AdapEq.AEQ_MIN_GAIN_TH_FIELD $M.AdapEq.AEQ_TONE_POWER_FIELD + 1;


.CONST $M.AdapEq.AEQ_MAX_GAIN_TH_FIELD $M.AdapEq.AEQ_MIN_GAIN_TH_FIELD + 1;


.CONST $M.AdapEq.AEQ_POWER_TEST_FIELD $M.AdapEq.AEQ_MAX_GAIN_TH_FIELD + 1;


.CONST $M.AdapEq.PTR_SCRATCH_G_FIELD $M.AdapEq.AEQ_POWER_TEST_FIELD + 1;


.CONST $M.AdapEq.STRUC_SIZE $M.AdapEq.PTR_SCRATCH_G_FIELD + 1;
.linefile 25 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf100/adf100_library.h" 1
.linefile 27 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf100/adf100_library.h"
.CONST $M.adf_alg_1_0_0_VERSION 0x010000;



.CONST $M.adf_alg_1_0_0.ADF_num_proc 55;
.CONST $M.adf_alg_1_0_0.Num_Taps 4;


.CONST $M.adf_alg_1_0_0.DATA_SIZE_DM1 (23 + 2*$M.adf_alg_1_0_0.Num_Taps)*$M.adf_alg_1_0_0.ADF_num_proc;

.CONST $M.adf_alg_1_0_0.DATA_SIZE_DM2 (19 + 2*$M.adf_alg_1_0_0.Num_Taps)*$M.adf_alg_1_0_0.ADF_num_proc + $M.adf_alg_1_0_0.Num_Taps+1;

.CONST $M.adf_alg_1_0_0.SCRATCH_SIZE_DM1 (5 * $M.adf_alg_1_0_0.ADF_num_proc);
.CONST $M.adf_alg_1_0_0.SCRATCH_SIZE_DM2 (1 * $M.adf_alg_1_0_0.ADF_num_proc);

.CONST $M.adf_alg_1_0_0.MGDC_param.Th0 3.98631371386483/128;
.CONST $M.adf_alg_1_0_0.MGDC_param.Th1 3.98631371386483/128;
.linefile 64 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf100/adf100_library.h"
.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_E_REAL_PTR 0;

.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_E_IMAG_PTR $M.adf_alg_1_0_0.OFFSET_FNLMS_E_REAL_PTR+1;

.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_D_EXP_PTR $M.adf_alg_1_0_0.OFFSET_FNLMS_E_IMAG_PTR+1;

.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_D_REAL_PTR $M.adf_alg_1_0_0.OFFSET_FNLMS_D_EXP_PTR+1;

.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_D_IMAG_PTR $M.adf_alg_1_0_0.OFFSET_FNLMS_D_REAL_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt $M.adf_alg_1_0_0.OFFSET_FNLMS_D_IMAG_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_RER_EXT_FUNC_PTR $M.adf_alg_1_0_0.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt+1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_D_REAL_PTR $M.adf_alg_1_0_0.OFFSET_RER_EXT_FUNC_PTR+1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_D_IMAG_PTR $M.adf_alg_1_0_0.OFFSET_RER_D_REAL_PTR +1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_Gr_imag $M.adf_alg_1_0_0.OFFSET_RER_D_IMAG_PTR+1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_Gr_real $M.adf_alg_1_0_0.OFFSET_RER_PTR_Gr_imag+1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_SqGr $M.adf_alg_1_0_0.OFFSET_RER_PTR_Gr_real+1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_L2absGr $M.adf_alg_1_0_0.OFFSET_RER_PTR_SqGr+1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_PTR_LPwrD $M.adf_alg_1_0_0.OFFSET_RER_PTR_L2absGr +1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_SCRPTR_W_ri $M.adf_alg_1_0_0.OFFSET_RER_PTR_LPwrD +1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_SCRPTR_L_adaptR $M.adf_alg_1_0_0.OFFSET_RER_SCRPTR_W_ri +1;

.CONST $M.adf_alg_1_0_0.OFFSET_RER_SQGRDEV $M.adf_alg_1_0_0.OFFSET_RER_SCRPTR_L_adaptR +1;





.CONST $M.adf_alg_1_0_0.OFFSET_X0_REAL_PTR $M.adf_alg_1_0_0.OFFSET_RER_SQGRDEV+1;


.CONST $M.adf_alg_1_0_0.OFFSET_X0_IMAG_PTR $M.adf_alg_1_0_0.OFFSET_X0_REAL_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_X0_EXP_PTR $M.adf_alg_1_0_0.OFFSET_X0_IMAG_PTR+1;

.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LPx0 $M.adf_alg_1_0_0.OFFSET_X0_EXP_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_X1_REAL_PTR $M.adf_alg_1_0_0.OFFSET_ADF_LPx0+1;


.CONST $M.adf_alg_1_0_0.OFFSET_X1_IMAG_PTR $M.adf_alg_1_0_0.OFFSET_X1_REAL_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_X1_EXP_PTR $M.adf_alg_1_0_0.OFFSET_X1_IMAG_PTR+1;

.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LPx1 $M.adf_alg_1_0_0.OFFSET_X1_EXP_PTR+1;




.CONST $M.adf_alg_1_0_0.OFFSET_PTR_DM1data $M.adf_alg_1_0_0.OFFSET_ADF_LPx1+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PTR_DM2data $M.adf_alg_1_0_0.OFFSET_PTR_DM1data+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PTR_DM1const $M.adf_alg_1_0_0.OFFSET_PTR_DM2data+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PTR_DM1tables $M.adf_alg_1_0_0.OFFSET_PTR_DM1const+1;
.linefile 147 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf100/adf100_library.h"
.CONST $M.adf_alg_1_0_0.OFFSET_SCRATCH_DM1 $M.adf_alg_1_0_0.OFFSET_PTR_DM1tables+1;




.CONST $M.adf_alg_1_0_0.OFFSET_SCRATCH_DM2 $M.adf_alg_1_0_0.OFFSET_SCRATCH_DM1+1;




.CONST $M.adf_alg_1_0_0.OFFSET_OMS_G_PTR $M.adf_alg_1_0_0.OFFSET_SCRATCH_DM2+1;


.CONST $M.adf_alg_1_0_0.OFFSET_E_OUT_REAL_PTR $M.adf_alg_1_0_0.OFFSET_OMS_G_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_E_OUT_IMAG_PTR $M.adf_alg_1_0_0.OFFSET_E_OUT_REAL_PTR+1;




.CONST $M.adf_alg_1_0_0.OFFSET_POSTPROC_FUNCPTR $M.adf_alg_1_0_0.OFFSET_E_OUT_IMAG_PTR+1;



.CONST $M.adf_alg_1_0_0.OFFSET_L_POSTP_CTRL_PTR $M.adf_alg_1_0_0.OFFSET_POSTPROC_FUNCPTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_NUMFREQ_BINS $M.adf_alg_1_0_0.OFFSET_L_POSTP_CTRL_PTR+1;




.CONST $M.adf_alg_1_0_0.OFFSET_CONTROL $M.adf_alg_1_0_0.OFFSET_NUMFREQ_BINS+1;


.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_PREP $M.adf_alg_1_0_0.OFFSET_CONTROL+1;


.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_MGDC $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_PREP+1;


.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_WIDE_MIC_ENA $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_MGDC+1;


.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_RPT_POSTP $M.adf_alg_1_0_0.OFFSET_BITMASK_WIDE_MIC_ENA+1;


.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_ADFPS $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_RPT_POSTP+1;


.CONST $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_ADFRNR $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_ADFPS+1;



.CONST $M.adf_alg_1_0_0.OFFSET_PP_GAMMAP $M.adf_alg_1_0_0.OFFSET_BITMASK_BYPASS_ADFRNR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PP_THRES $M.adf_alg_1_0_0.OFFSET_PP_GAMMAP+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PP_VAD_DETECT $M.adf_alg_1_0_0.OFFSET_PP_THRES+1;



.CONST $M.adf_alg_1_0_0.OFFSET_PP_VAD_THRES $M.adf_alg_1_0_0.OFFSET_PP_VAD_DETECT+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PP_CTRL_BIAS $M.adf_alg_1_0_0.OFFSET_PP_VAD_THRES+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PP_CTRL_TRANS $M.adf_alg_1_0_0.OFFSET_PP_CTRL_BIAS+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_ALFAD $M.adf_alg_1_0_0.OFFSET_PP_CTRL_TRANS+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_FRONTMICBIAS $M.adf_alg_1_0_0.OFFSET_MGDC_ALFAD+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_MAXCOMP $M.adf_alg_1_0_0.OFFSET_MGDC_FRONTMICBIAS+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_ADAPT_THRESH $M.adf_alg_1_0_0.OFFSET_MGDC_MAXCOMP+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_K_LB $M.adf_alg_1_0_0.OFFSET_MGDC_ADAPT_THRESH+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_K_HB $M.adf_alg_1_0_0.OFFSET_MGDC_K_LB+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_MEAN_SCL_EXP $M.adf_alg_1_0_0.OFFSET_MGDC_K_HB+1;

.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_MEAN_SCL_MTS $M.adf_alg_1_0_0.OFFSET_MGDC_MEAN_SCL_EXP+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_TH0 $M.adf_alg_1_0_0.OFFSET_MGDC_MEAN_SCL_MTS+1;


.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_TH1 $M.adf_alg_1_0_0.OFFSET_MGDC_TH0+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PTR_WIND_DETECT $M.adf_alg_1_0_0.OFFSET_MGDC_TH1+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PTR_ADF_HOLD $M.adf_alg_1_0_0.OFFSET_PTR_WIND_DETECT+1;


.CONST $M.adf_alg_1_0_0.OFFSET_DMSS_WEIGHT $M.adf_alg_1_0_0.OFFSET_PTR_ADF_HOLD+1;


.CONST $M.adf_alg_1_0_0.OFFSET_OMS_LPXNZ_PTR $M.adf_alg_1_0_0.OFFSET_DMSS_WEIGHT+1;


.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPS_ON $M.adf_alg_1_0_0.OFFSET_OMS_LPXNZ_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPS_OFF $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPS_ON+1;


.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_CLEAN $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPS_OFF+1;


.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_NOISY $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_CLEAN+1;


.CONST $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_POSTP $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_NOISY+1;


.CONST $M.adf_alg_1_0_0.OFFSET_TH_ADF_DLPZ $M.adf_alg_1_0_0.OFFSET_L2TH_ADFPSV_POSTP+1;


.CONST $M.adf_alg_1_0_0.OFFSET_PREP_DT_MIC $M.adf_alg_1_0_0.OFFSET_TH_ADF_DLPZ+1;


.CONST $M.adf_alg_1_0_0.OFFSET_SQRT_PREP_SUBFACTOR $M.adf_alg_1_0_0.OFFSET_PREP_DT_MIC+1;


.CONST $M.adf_alg_1_0_0.OFFSET_REPL_ADJUST $M.adf_alg_1_0_0.OFFSET_SQRT_PREP_SUBFACTOR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_REPL_POWER $M.adf_alg_1_0_0.OFFSET_REPL_ADJUST+1;
.linefile 304 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf100/adf100_library.h"
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_ALFA $M.adf_alg_1_0_0.OFFSET_REPL_POWER+1;


.CONST $M.adf_alg_1_0_0.OFFSET_RNR_ADJUST $M.adf_alg_1_0_0.OFFSET_RNR_ALFA+1;


.CONST $M.adf_alg_1_0_0.OFFSET_RNR_BIAS $M.adf_alg_1_0_0.OFFSET_RNR_ADJUST+1;


.CONST $M.adf_alg_1_0_0.OFFSET_RNR_TRANS $M.adf_alg_1_0_0.OFFSET_RNR_BIAS+1;




.CONST $M.adf_alg_1_0_0.OFFSET_L2FBpXD $M.adf_alg_1_0_0.OFFSET_RNR_TRANS+1;




.CONST $M.adf_alg_1_0_0.OFFSET_INTERNAL_START $M.adf_alg_1_0_0.OFFSET_L2FBpXD+1;



.CONST $M.adf_alg_1_0_0.OFFSET_PTR_V0_real $M.adf_alg_1_0_0.OFFSET_INTERNAL_START+0;
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_V0_imag $M.adf_alg_1_0_0.OFFSET_PTR_V0_real+1;
.CONST $M.adf_alg_1_0_0.OFFSET_V0_EXP_PTR $M.adf_alg_1_0_0.OFFSET_PTR_V0_imag+1;
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LPz0 $M.adf_alg_1_0_0.OFFSET_V0_EXP_PTR+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_V1_real $M.adf_alg_1_0_0.OFFSET_ADF_LPz0+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PTR_V1_imag $M.adf_alg_1_0_0.OFFSET_PTR_V1_real+1;
.CONST $M.adf_alg_1_0_0.OFFSET_V1_EXP_PTR $M.adf_alg_1_0_0.OFFSET_PTR_V1_imag+1;
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LPz1 $M.adf_alg_1_0_0.OFFSET_V1_EXP_PTR+1;


.CONST $M.adf_alg_1_0_0.OFFSET_muAt $M.adf_alg_1_0_0.OFFSET_ADF_LPz1+1;


.CONST $M.adf_alg_1_0_0.OFFSET_ct_Px0 $M.adf_alg_1_0_0.OFFSET_muAt+1;
.CONST $M.adf_alg_1_0_0.OFFSET_dL2Px0FB $M.adf_alg_1_0_0.OFFSET_ct_Px0+1;
.CONST $M.adf_alg_1_0_0.OFFSET_L2Px0t0 $M.adf_alg_1_0_0.OFFSET_dL2Px0FB+1;

.CONST $M.adf_alg_1_0_0.OFFSET_ct_Px1 $M.adf_alg_1_0_0.OFFSET_L2Px0t0+1;
.CONST $M.adf_alg_1_0_0.OFFSET_dL2Px1FB $M.adf_alg_1_0_0.OFFSET_ct_Px1+1;
.CONST $M.adf_alg_1_0_0.OFFSET_L2Px1t0 $M.adf_alg_1_0_0.OFFSET_dL2Px1FB+1;

.CONST $M.adf_alg_1_0_0.OFFSET_ct_init $M.adf_alg_1_0_0.OFFSET_L2Px1t0+1;

.CONST $M.adf_alg_1_0_0.OFFSET_MGDCexp $M.adf_alg_1_0_0.OFFSET_ct_init+1;
.CONST $M.adf_alg_1_0_0.OFFSET_MGDCmts $M.adf_alg_1_0_0.OFFSET_MGDCexp+1;

.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_L2FBpXDst $M.adf_alg_1_0_0.OFFSET_MGDCmts+1;
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_hold_adapt $M.adf_alg_1_0_0.OFFSET_MGDC_L2FBpXDst+1;
.CONST $M.adf_alg_1_0_0.OFFSET_MGDC_switch_output $M.adf_alg_1_0_0.OFFSET_MGDC_hold_adapt+1;
.CONST $M.adf_alg_1_0_0.OFFSET_adfps_option_func $M.adf_alg_1_0_0.OFFSET_MGDC_switch_output+1;
.CONST $M.adf_alg_1_0_0.OFFSET_adfps_mode $M.adf_alg_1_0_0.OFFSET_adfps_option_func+1;
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_Diff_LPz $M.adf_alg_1_0_0.OFFSET_adfps_mode+1;

.CONST $M.adf_alg_1_0_0.OFFSET_PreP_func_ptr $M.adf_alg_1_0_0.OFFSET_ADF_Diff_LPz+1;

.CONST $M.adf_alg_1_0_0.OFFSET_PreP_sub_factor $M.adf_alg_1_0_0.OFFSET_PreP_func_ptr+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PreP_sub_factor_T $M.adf_alg_1_0_0.OFFSET_PreP_sub_factor+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PreP_G_mgdc_fmb $M.adf_alg_1_0_0.OFFSET_PreP_sub_factor_T+1;

.CONST $M.adf_alg_1_0_0.OFFSET_G_RatioX1X0 $M.adf_alg_1_0_0.OFFSET_PreP_G_mgdc_fmb+1;
.CONST $M.adf_alg_1_0_0.OFFSET_ADF_LALFALPZ $M.adf_alg_1_0_0.OFFSET_G_RatioX1X0+1;

.CONST $M.adf_alg_1_0_0.OFFSET_num_taps $M.adf_alg_1_0_0.OFFSET_ADF_LALFALPZ+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PP_kL $M.adf_alg_1_0_0.OFFSET_num_taps+1;
.CONST $M.adf_alg_1_0_0.OFFSET_PP_kH $M.adf_alg_1_0_0.OFFSET_PP_kL+1;
.CONST $M.adf_alg_1_0_0.OFFSET_compara_mn_factor $M.adf_alg_1_0_0.OFFSET_PP_kH+1;


.CONST $M.adf_alg_1_0_0.OFFSET_bypass_mgdc $M.adf_alg_1_0_0.OFFSET_compara_mn_factor+1;
.CONST $M.adf_alg_1_0_0.OFFSET_bypass_postp_rpt $M.adf_alg_1_0_0.OFFSET_bypass_mgdc+1;
.CONST $M.adf_alg_1_0_0.OFFSET_wide_mic_enabled $M.adf_alg_1_0_0.OFFSET_bypass_postp_rpt+1;


.CONST $M.adf_alg_1_0_0.OFFSET_L2Th_adfps $M.adf_alg_1_0_0.OFFSET_wide_mic_enabled+1;
.CONST $M.adf_alg_1_0_0.OFFSET_L2Th_adfps_alpha $M.adf_alg_1_0_0.OFFSET_L2Th_adfps+1;


.CONST $M.adf_alg_1_0_0.OFFSET_LpXfb_adfps $M.adf_alg_1_0_0.OFFSET_L2Th_adfps_alpha+1;
.CONST $M.adf_alg_1_0_0.OFFSET_LpXfb_adfps_alpha $M.adf_alg_1_0_0.OFFSET_LpXfb_adfps+1;


.CONST $M.adf_alg_1_0_0.OFFSET_LpVa $M.adf_alg_1_0_0.OFFSET_LpXfb_adfps_alpha+1;
.CONST $M.adf_alg_1_0_0.OFFSET_LpVa_alpha $M.adf_alg_1_0_0.OFFSET_LpVa+1;


.CONST $M.adf_alg_1_0_0.OFFSET_LpVp $M.adf_alg_1_0_0.OFFSET_LpVa_alpha+1;
.CONST $M.adf_alg_1_0_0.OFFSET_LpVp_alpha $M.adf_alg_1_0_0.OFFSET_LpVp+1;


.CONST $M.adf_alg_1_0_0.OFFSET_RNR_BYPASS_FLAG $M.adf_alg_1_0_0.OFFSET_LpVp_alpha+1;
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_DIFF_DLPZ $M.adf_alg_1_0_0.OFFSET_RNR_BYPASS_FLAG+1;
.CONST $M.adf_alg_1_0_0.OFFSET_RNR_ADJUST_USED $M.adf_alg_1_0_0.OFFSET_RNR_DIFF_DLPZ+1;


.CONST $M.adf_alg_1_0_0.OFFSET_G_HB $M.adf_alg_1_0_0.OFFSET_RNR_ADJUST_USED+1;


.CONST $M.adf_alg_1_0_0.STRUCT_SIZE $M.adf_alg_1_0_0.OFFSET_G_HB+1;




.CONST $MAX_24 0x7fffff;
.CONST $MIN_24 0x800000;
.CONST $MIN_48_MSB 0x800000;
.CONST $MIN_48_LSB 0;
.CONST $MAX_48_MSB 0x7fffff;
.CONST $MAX_48_LSB 0xffffff;
.linefile 26 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/ssr/ssr_library.h" 1
.linefile 16 "C:/ADK3.5/kalimba/lib_sets/sdk/include/ssr/ssr_library.h"
.CONST $SSR_VERSION 0x010200;
.linefile 31 "C:/ADK3.5/kalimba/lib_sets/sdk/include/ssr/ssr_library.h"
.CONST $M.SSR.SAMP_FREQ 8000;
.CONST $M.SSR.FRAME_SIZE 128;
.CONST $M.SSR.FFT_SIZE $M.SSR.FRAME_SIZE;
.CONST $M.SSR.NUM_FILTERS 23;
.CONST $M.SSR.MFCC_ORDER 12;
.CONST $M.SSR.L2_FFTS2 6;
.CONST $M.SSR.ENORM 356;
.CONST $M.SSR.KLOG2 2839;
.CONST $M.SSR.MAX_REG 0x7FFFFF;
.CONST $M.SSR.MIN_REG 0x800000;

.CONST $M.SSR.NMODELS 5;
.CONST $M.SSR.NSTATES 5;
.CONST $M.SSR.NPARAMS ($M.SSR.MFCC_ORDER+1);
.CONST $M.SSR.DELTAWIN 2;
.CONST $M.SSR.OBS_SIZE ($M.SSR.NPARAMS*$M.SSR.DELTAWIN);
.CONST $M.SSR.REGRESS_COLS (2*$M.SSR.DELTAWIN+1);
.CONST $M.SSR.LZERO ($M.SSR.MIN_REG + (4*(1<<12)));
.CONST $M.SSR.DELTACONST (409);
.CONST $M.SSR.BEAMTHRESHOLD ($M.SSR.LZERO>>1);




.CONST $M.SSR.WORD_TOO_SHORT 7;
.CONST $M.SSR.MIN_FINAL_STATES 2;





.CONST $M.SSR.MIN_SUCC_ST 0;
.CONST $M.SSR.MIN_MAIN_ST 0;

.CONST $M.SSR.FORCE_UNCERT -327680;
.CONST $M.SSR.SCORE_BIAS 196608;
.CONST $M.SSR.UNCERT_POS 3;
.CONST $M.SSR.CANDIDATE_STRENGTH 2;

.CONST $M.SSR.NOISE_BASE (-24);
.CONST $M.SSR.UNCERT_OFFSET (-112);
.CONST $M.SSR.UTTERANCE_TIME_OUT 3000;





.CONST $M.SSR.VOICE_DISAPPEARED 4;
.CONST $M.SSR.MIN_VALID_WORD 18;




.CONST $M.SSR.LPDNZ_PAD 8192;
.CONST $M.SSR.L2_LPDNZ_TRANS 1;
.CONST $M.SSR.LPDNZ_MARGIN 3*(1<<12);

.CONST $M.SSR.MAX_AGGRESS 0x7FFFFF;




.CONST $M.SSR.A_CONFI_THR_Yes -6963;
.CONST $M.SSR.A_CONFI_THR_No -6144;




.CONST $M.SSR.SSR_STRUC.CBUFFER_IN_OFFSET 0;
.CONST $M.SSR.SSR_STRUC.NOISE_BASE_OFFSET $M.SSR.SSR_STRUC.CBUFFER_IN_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.UNCERT_OFFSET $M.SSR.SSR_STRUC.NOISE_BASE_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.TIME_OUT_OFFSET $M.SSR.SSR_STRUC.UNCERT_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.RECOGNISED_WORD_OFFSET $M.SSR.SSR_STRUC.TIME_OUT_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.UNCERT_FLAG_OFFSET $M.SSR.SSR_STRUC.RECOGNISED_WORD_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.FINISH_OFFSET $M.SSR.SSR_STRUC.UNCERT_FLAG_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.CONFIDENCE_SCORE_OFFSET $M.SSR.SSR_STRUC.FINISH_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.ASRDEC_PTR_OFFSET $M.SSR.SSR_STRUC.CONFIDENCE_SCORE_OFFSET + 1;

.CONST $M.SSR.SSR_STRUC.FFT_REAL_OFFSET $M.SSR.SSR_STRUC.ASRDEC_PTR_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.FFT_IMAG_OFFSET $M.SSR.SSR_STRUC.FFT_REAL_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.SCALE_FACTOR_OFFSET $M.SSR.SSR_STRUC.FFT_IMAG_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.VOICED_OFFSET $M.SSR.SSR_STRUC.SCALE_FACTOR_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.GAIN_OFFSET $M.SSR.SSR_STRUC.VOICED_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.LIKE_MEAN_OFFSET $M.SSR.SSR_STRUC.GAIN_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.LPX_NZ_OFFSET $M.SSR.SSR_STRUC.LIKE_MEAN_OFFSET + 1;
.CONST $M.SSR.SSR_STRUC.BLOCK_SIZE $M.SSR.SSR_STRUC.LPX_NZ_OFFSET + 1;




.CONST $M.SSR.HMMDEF.NAME_OFFSET 0;
.CONST $M.SSR.HMMDEF.NSTATES_OFFSET $M.SSR.HMMDEF.NAME_OFFSET + 1;
.CONST $M.SSR.HMMDEF.GMMS_OFFSET $M.SSR.HMMDEF.NSTATES_OFFSET + 1;
.CONST $M.SSR.HMMDEF.EMISSION_TYPE_OFFSET $M.SSR.HMMDEF.GMMS_OFFSET + 1;
.CONST $M.SSR.HMMDEF.START_PROB_OFFSET $M.SSR.HMMDEF.EMISSION_TYPE_OFFSET + 1;
.CONST $M.SSR.HMMDEF.END_PROB_OFFSET $M.SSR.HMMDEF.START_PROB_OFFSET + 1;
.CONST $M.SSR.HMMDEF.TRANSMAT_OFFSET $M.SSR.HMMDEF.END_PROB_OFFSET + 1;
.CONST $M.SSR.HMMDEF.TIDX_OFFSET $M.SSR.HMMDEF.TRANSMAT_OFFSET + 1;
.CONST $M.SSR.HMMDEF.PARTIAL_LIKE_OFFSET $M.SSR.HMMDEF.TIDX_OFFSET + 1;
.CONST $M.SSR.HMMDEF.MAX_LIKE_OFFSET $M.SSR.HMMDEF.PARTIAL_LIKE_OFFSET + 1;
.CONST $M.SSR.HMMDEF.MAX_STATE_OFFSET $M.SSR.HMMDEF.MAX_LIKE_OFFSET + 1;
.CONST $M.SSR.HMMDEF.BLOCK_SIZE $M.SSR.HMMDEF.MAX_STATE_OFFSET + 1;




.CONST $M.SSR.DECODER_STRUCT.HMM_SET_OFFSET 0;
.CONST $M.SSR.DECODER_STRUCT.FINISH_OFFSET $M.SSR.DECODER_STRUCT.HMM_SET_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.RESET_OFFSET $M.SSR.DECODER_STRUCT.FINISH_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.BEST_WORD_OFFSET $M.SSR.DECODER_STRUCT.RESET_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.BEST_SCORE_OFFSET $M.SSR.DECODER_STRUCT.BEST_WORD_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.BEST_STATE_OFFSET $M.SSR.DECODER_STRUCT.BEST_SCORE_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.OBS_OFFSET $M.SSR.DECODER_STRUCT.BEST_STATE_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.OBS_REGRESS_OFFSET $M.SSR.DECODER_STRUCT.OBS_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.LOG_ENERGY_OFFSET $M.SSR.DECODER_STRUCT.OBS_REGRESS_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.CONFIDENCE_SCORE_OFFSET $M.SSR.DECODER_STRUCT.LOG_ENERGY_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.NR_BEST_FRAMES_OFFSET $M.SSR.DECODER_STRUCT.CONFIDENCE_SCORE_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.SUCC_STA_CNT_OFFSET $M.SSR.DECODER_STRUCT.NR_BEST_FRAMES_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.NR_MAIN_STATE_OFFSET $M.SSR.DECODER_STRUCT.SUCC_STA_CNT_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.FINISH_CNT_OFFSET $M.SSR.DECODER_STRUCT.NR_MAIN_STATE_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.RELIABILITY_OFFSET $M.SSR.DECODER_STRUCT.FINISH_CNT_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.DECODER_STARTED_OFFSET $M.SSR.DECODER_STRUCT.RELIABILITY_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.FRAME_COUNTER_OFFSET $M.SSR.DECODER_STRUCT.DECODER_STARTED_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.VOICE_GONE_CNT_OFFSET $M.SSR.DECODER_STRUCT.FRAME_COUNTER_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.AFTER_RESET_CNT_OFFSET $M.SSR.DECODER_STRUCT.VOICE_GONE_CNT_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.SCORE_OFFSET $M.SSR.DECODER_STRUCT.AFTER_RESET_CNT_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.SUM_RELI_OFFSET $M.SSR.DECODER_STRUCT.SCORE_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.NOISE_ESTIMATE_OFFSET $M.SSR.DECODER_STRUCT.SUM_RELI_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.NOISE_FRAME_COUNTER_OFFSET $M.SSR.DECODER_STRUCT.NOISE_ESTIMATE_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.INITIALIZED_OFFSET $M.SSR.DECODER_STRUCT.NOISE_FRAME_COUNTER_OFFSET + 1;

.CONST $M.SSR.DECODER_STRUCT.FBANK_COEFFS_OFFSET $M.SSR.DECODER_STRUCT.INITIALIZED_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.MFC_COEFFS_OFFSET $M.SSR.DECODER_STRUCT.FBANK_COEFFS_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.PARTIAL_LIKE_OFFSET $M.SSR.DECODER_STRUCT.MFC_COEFFS_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.PARTIAL_LIKE_NEXT_OFFSET $M.SSR.DECODER_STRUCT.PARTIAL_LIKE_OFFSET + 1;
.CONST $M.SSR.DECODER_STRUCT.BLOCK_SIZE $M.SSR.DECODER_STRUCT.PARTIAL_LIKE_NEXT_OFFSET + 1;


.CONST $M.SSR.MIXTURE_STRUCT.MIX_ID_OFFSET 0;
.CONST $M.SSR.MIXTURE_STRUCT.PRIORS_OFFSET $M.SSR.MIXTURE_STRUCT.MIX_ID_OFFSET + 1;
.CONST $M.SSR.MIXTURE_STRUCT.GCONST_OFFSET $M.SSR.MIXTURE_STRUCT.PRIORS_OFFSET + 1;
.CONST $M.SSR.MIXTURE_STRUCT.MEANS_OFFSET $M.SSR.MIXTURE_STRUCT.GCONST_OFFSET + 1;
.CONST $M.SSR.MIXTURE_STRUCT.COVARS_OFFSET $M.SSR.MIXTURE_STRUCT.MEANS_OFFSET + 1;
.CONST $M.SSR.MIXTURE_STRUCT.BLOCK_SIZE_OFFSET $M.SSR.MIXTURE_STRUCT.COVARS_OFFSET + 1;


.CONST $M.SSR.STATEDEF.NMIX_OFFSET 0;
.CONST $M.SSR.STATEDEF.MIX_OFFSET $M.SSR.STATEDEF.NMIX_OFFSET + 1;
.CONST $M.SSR.STATEDEF.BLOCK_SIZE_OFFSET $M.SSR.STATEDEF.MIX_OFFSET + 1;




.CONST $M.SSR.OMS_STRUC.OMS_OBJ_OFFSET 0;
.CONST $M.SSR.OMS_STRUC.FFT_REAL_OFFSET $M.SSR.OMS_STRUC.OMS_OBJ_OFFSET + 1;
.CONST $M.SSR.OMS_STRUC.FFT_IMAG_OFFSET $M.SSR.OMS_STRUC.FFT_REAL_OFFSET + 1;
.CONST $M.SSR.OMS_STRUC.SCALE_FACTOR_OFFSET $M.SSR.OMS_STRUC.FFT_IMAG_OFFSET + 1;
.CONST $M.SSR.OMS_STRUC.VOICED_OFFSET $M.SSR.OMS_STRUC.SCALE_FACTOR_OFFSET + 1;
.CONST $M.SSR.OMS_STRUC.GAIN_OFFSET $M.SSR.OMS_STRUC.VOICED_OFFSET + 1;
.CONST $M.SSR.OMS_STRUC.LIKE_MEAN_OFFSET $M.SSR.OMS_STRUC.GAIN_OFFSET + 1;
.CONST $M.SSR.OMS_STRUC.LPX_NZ_OFFSET $M.SSR.OMS_STRUC.LIKE_MEAN_OFFSET + 1;
.CONST $M.SSR.OMS_STRUC.BLOCK_SIZE_OFFSET $M.SSR.OMS_STRUC.LPX_NZ_OFFSET + 1;
.linefile 27 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/Beamformer100/2micHF500_library.h" 1


.CONST $M.BEAMFORMER.BIN_L 2;
.CONST $M.BEAMFORMER.BIN_H 63;
.CONST $M.BEAMFORMER.PROCESSING_BINS ($M.BEAMFORMER.BIN_H - $M.BEAMFORMER.BIN_L + 1);


.CONST $M.AED.BIN_L 5;
.CONST $M.AED.BIN_H 59;
.CONST $M.AED.IDX_PROC ($M.AED.BIN_H - $M.AED.BIN_L + 1);
.CONST $M.AED.IDX_PROC_INV 0x0253C8;


.CONST $M.TWOCHANNEL_NC.BIN_L 5;
.CONST $M.TWOCHANNEL_NC.BIN_H 59;
.CONST $M.TWOCHANNEL_NC.NC_num_proc ($M.TWOCHANNEL_NC.BIN_H - $M.TWOCHANNEL_NC.BIN_L + 1);
.CONST $M.TWOCHANNEL_NC.Num_Taps 2;

.CONST $M.BEAMFORMER.OFFSET_X0_REAL_PTR 0;
.CONST $M.BEAMFORMER.OFFSET_X0_IMAG_PTR $M.BEAMFORMER.OFFSET_X0_REAL_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_BEXP_X0_PTR $M.BEAMFORMER.OFFSET_X0_IMAG_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_X1_REAL_PTR $M.BEAMFORMER.OFFSET_BEXP_X0_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_X1_IMAG_PTR $M.BEAMFORMER.OFFSET_X1_REAL_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_BEXP_X1_PTR $M.BEAMFORMER.OFFSET_X1_IMAG_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_Z_REAL_PTR $M.BEAMFORMER.OFFSET_BEXP_X1_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_Z_IMAG_PTR $M.BEAMFORMER.OFFSET_Z_REAL_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_MU_PTR $M.BEAMFORMER.OFFSET_Z_IMAG_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_BEAM_MODE $M.BEAMFORMER.OFFSET_MU_PTR + 1;
.CONST $M.BEAMFORMER.OFFSET_ELEMENT_D $M.BEAMFORMER.OFFSET_BEAM_MODE + 1;
.CONST $M.BEAMFORMER.OFFSET_DOA $M.BEAMFORMER.OFFSET_ELEMENT_D + 1;
.CONST $M.BEAMFORMER.OFFSET_PTR_DM1data $M.BEAMFORMER.OFFSET_DOA + 1;
.CONST $M.BEAMFORMER.OFFSET_SCRATCH_DM1 $M.BEAMFORMER.OFFSET_PTR_DM1data + 1;
.CONST $M.BEAMFORMER.OFFSET_SCRATCH_DM2 $M.BEAMFORMER.OFFSET_SCRATCH_DM1 + 1;
.CONST $M.BEAMFORMER.STRUC_SIZE $M.BEAMFORMER.OFFSET_SCRATCH_DM2 + 1;


.CONST $M.TWOMIC_HF_500.OFFSET_CONFIG 0;
.CONST $M.TWOMIC_HF_500.OFFSET_MIC_MODE $M.TWOMIC_HF_500.OFFSET_CONFIG + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_MGDC_CTRL $M.TWOMIC_HF_500.OFFSET_MIC_MODE + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_BF0_PTR $M.TWOMIC_HF_500.OFFSET_MGDC_CTRL + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_BF1_PTR $M.TWOMIC_HF_500.OFFSET_BF0_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_2MICAEC_PTR $M.TWOMIC_HF_500.OFFSET_BF1_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_AED_PTR $M.TWOMIC_HF_500.OFFSET_2MICAEC_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_2CHNC_PTR $M.TWOMIC_HF_500.OFFSET_AED_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_OMS_IN_PTR $M.TWOMIC_HF_500.OFFSET_2CHNC_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_OMS_OUT0_PTR $M.TWOMIC_HF_500.OFFSET_OMS_IN_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_OMS_OUT1_PTR $M.TWOMIC_HF_500.OFFSET_OMS_OUT0_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_NUM_BINS $M.TWOMIC_HF_500.OFFSET_OMS_OUT1_PTR + 1;

.CONST $M.TWOMIC_HF_500.OFFSET_X0_REAL_PTR $M.TWOMIC_HF_500.OFFSET_NUM_BINS + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_X0_IMAG_PTR $M.TWOMIC_HF_500.OFFSET_X0_REAL_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_BEXP_X0_PTR $M.TWOMIC_HF_500.OFFSET_X0_IMAG_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_X1_REAL_PTR $M.TWOMIC_HF_500.OFFSET_BEXP_X0_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_X1_IMAG_PTR $M.TWOMIC_HF_500.OFFSET_X1_REAL_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_BEXP_X1_PTR $M.TWOMIC_HF_500.OFFSET_X1_IMAG_PTR+ 1;

.CONST $M.TWOMIC_HF_500.OFFSET_Z0_REAL_PTR $M.TWOMIC_HF_500.OFFSET_BEXP_X1_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_Z0_IMAG_PTR $M.TWOMIC_HF_500.OFFSET_Z0_REAL_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_Z1_REAL_PTR $M.TWOMIC_HF_500.OFFSET_Z0_IMAG_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_Z1_IMAG_PTR $M.TWOMIC_HF_500.OFFSET_Z1_REAL_PTR + 1;

.CONST $M.TWOMIC_HF_500.OFFSET_TMP_LalfaLPz_PTR $M.TWOMIC_HF_500.OFFSET_Z1_IMAG_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_TMP_LPin0_PTR $M.TWOMIC_HF_500.OFFSET_TMP_LalfaLPz_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_TMP_LPin1_PTR $M.TWOMIC_HF_500.OFFSET_TMP_LPin0_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_TMP_LPout0_PTR $M.TWOMIC_HF_500.OFFSET_TMP_LPin1_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_TMP_LPout1_PTR $M.TWOMIC_HF_500.OFFSET_TMP_LPout0_PTR + 1;
.CONST $M.TWOMIC_HF_500.OFFSET_PTR_DM1data $M.TWOMIC_HF_500.OFFSET_TMP_LPout1_PTR + 1;
.CONST $M.TWOMIC_HF_500.STRUC_SIZE $M.TWOMIC_HF_500.OFFSET_PTR_DM1data + 1;




.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_E_REAL_PTR 0;

.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_E_IMAG_PTR $M.TWOMIC_AEC.OFFSET_FNLMS_E_REAL_PTR+1;

.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_EXP_PTR $M.TWOMIC_AEC.OFFSET_FNLMS_E_IMAG_PTR+1;

.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_REAL_PTR $M.TWOMIC_AEC.OFFSET_FNLMS_D_EXP_PTR+1;

.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_D_IMAG_PTR $M.TWOMIC_AEC.OFFSET_FNLMS_D_REAL_PTR+1;


.CONST $M.TWOMIC_AEC.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt $M.TWOMIC_AEC.OFFSET_FNLMS_D_IMAG_PTR + 1;

.CONST $M.TWOMIC_AEC.OFFSET_PTR_MAIN_AEC $M.TWOMIC_AEC.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1 $M.TWOMIC_AEC.OFFSET_PTR_MAIN_AEC + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_Ga_real $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1 + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_Ga_imag $M.TWOMIC_AEC.OFFSET_PTR_Ga_real + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_BExp_Ga $M.TWOMIC_AEC.OFFSET_PTR_Ga_imag + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_real $M.TWOMIC_AEC.OFFSET_PTR_BExp_Ga + 1;
.CONST $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_imag $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_real + 1;

.CONST $M.TWOMIC_AEC.STRUCT_SIZE $M.TWOMIC_AEC.OFFSET_PTR_RcvBuf_imag + 1;


.CONST $M.AED.OFFSET_G_OMS0 0;
.CONST $M.AED.OFFSET_VOICED_OMS0 $M.AED.OFFSET_G_OMS0 + 1;
.CONST $M.AED.OFFSET_G_OMS1 $M.AED.OFFSET_VOICED_OMS0 + 1;
.CONST $M.AED.OFFSET_VOICED_OMS1 $M.AED.OFFSET_G_OMS1 + 1;
.CONST $M.AED.OFFSET_VOICEFLAG $M.AED.OFFSET_VOICED_OMS1 + 1;
.CONST $M.AED.OFFSET_MODE $M.AED.OFFSET_VOICEFLAG + 1;
.CONST $M.AED.OFFSET_STATE_T $M.AED.OFFSET_MODE + 1;
.CONST $M.AED.OFFSET_VAD $M.AED.OFFSET_STATE_T + 1;
.CONST $M.AED.OFFSET_CHANNEL $M.AED.OFFSET_VAD + 1;
.CONST $M.AED.OFFSET_G_AED $M.AED.OFFSET_CHANNEL + 1;
.CONST $M.AED.OFFSET_Noise_Th $M.AED.OFFSET_G_AED + 1;
.CONST $M.AED.OFFSET_alphaA $M.AED.OFFSET_Noise_Th + 1;
.CONST $M.AED.OFFSET_alphaN $M.AED.OFFSET_alphaA + 1;
.CONST $M.AED.OFFSET_NR_defer_Count $M.AED.OFFSET_alphaN + 1;
.CONST $M.AED.OFFSET_NR_max_Count $M.AED.OFFSET_NR_defer_Count + 1;
.CONST $M.AED.OFFSET_NR_alpha $M.AED.OFFSET_NR_max_Count + 1;
.CONST $M.AED.OFFSET_S_ACTIVE_COUNT $M.AED.OFFSET_NR_alpha + 1;
.CONST $M.AED.OFFSET_S_ACTIVE_COUNT_DIV_6 $M.AED.OFFSET_S_ACTIVE_COUNT + 1;
.CONST $M.AED.OFFSET_PTR_DM1data $M.AED.OFFSET_S_ACTIVE_COUNT_DIV_6 + 1;
.CONST $M.AED.STRUC_SIZE $M.AED.OFFSET_PTR_DM1data + 1;


.CONST $M.TWOCHANNEL_NC.OFFSET_E_REAL_PTR 0;
.CONST $M.TWOCHANNEL_NC.OFFSET_E_IMAG_PTR $M.TWOCHANNEL_NC.OFFSET_E_REAL_PTR + 1;
.CONST $M.TWOCHANNEL_NC.OFFSET_BEXP_D_PTR $M.TWOCHANNEL_NC.OFFSET_E_IMAG_PTR + 1;
.CONST $M.TWOCHANNEL_NC.OFFSET_D_REAL_PTR $M.TWOCHANNEL_NC.OFFSET_BEXP_D_PTR + 1;
.CONST $M.TWOCHANNEL_NC.OFFSET_D_IMAG_PTR $M.TWOCHANNEL_NC.OFFSET_D_REAL_PTR + 1;
.CONST $M.TWOCHANNEL_NC.OFFSET_SCRPTR_Exp_Mts_adapt $M.TWOCHANNEL_NC.OFFSET_D_IMAG_PTR + 1;

.CONST $M.TWOCHANNEL_NC.OFFSET_X_REAL_PTR $M.TWOCHANNEL_NC.OFFSET_SCRPTR_Exp_Mts_adapt + 1;
.CONST $M.TWOCHANNEL_NC.OFFSET_X_IMAG_PTR $M.TWOCHANNEL_NC.OFFSET_X_REAL_PTR + 1;
.CONST $M.TWOCHANNEL_NC.OFFSET_BEXP_X_PTR $M.TWOCHANNEL_NC.OFFSET_X_IMAG_PTR + 1;


.CONST $M.TWOCHANNEL_NC.OFFSET_AED_DIFF_PTR $M.TWOCHANNEL_NC.OFFSET_BEXP_X_PTR+1;


.CONST $M.TWOCHANNEL_NC.OFFSET_PP_GAMMAP $M.TWOCHANNEL_NC.OFFSET_AED_DIFF_PTR + 1;
.CONST $M.TWOCHANNEL_NC.OFFSET_bypass_postp_rpt $M.TWOCHANNEL_NC.OFFSET_PP_GAMMAP + 1;
.CONST $M.TWOCHANNEL_NC.OFFSET_num_taps $M.TWOCHANNEL_NC.OFFSET_bypass_postp_rpt + 1;
.linefile 146 "C:/ADK3.5/kalimba/lib_sets/sdk/include/Beamformer100/2micHF500_library.h"
.CONST $M.TWOCHANNEL_NC.OFFSET_SCRATCH_DM1 $M.TWOCHANNEL_NC.OFFSET_num_taps+1;




.CONST $M.TWOCHANNEL_NC.OFFSET_SCRATCH_DM2 $M.TWOCHANNEL_NC.OFFSET_SCRATCH_DM1+1;




.CONST $M.TWOCHANNEL_NC.OFFSET_PTR_DM1data $M.TWOCHANNEL_NC.OFFSET_SCRATCH_DM2+1;


.CONST $M.TWOCHANNEL_NC.OFFSET_PTR_DM2data $M.TWOCHANNEL_NC.OFFSET_PTR_DM1data+1;


.CONST $M.TWOCHANNEL_NC.STRUC_SIZE $M.TWOCHANNEL_NC.OFFSET_PTR_DM2data + 1;

.CONST $M.TWOCHANNEL_NC.OFFSET_SCR2PTR_PP_LpXt $M.TWOCHANNEL_NC.OFFSET_SCRATCH_DM2;






.CONST $M.AED.OFFSET_DM1PTR_Diff $M.AED.OFFSET_PTR_DM1data;
.CONST $M.AED.DM1.Diff 0;
.CONST $M.AED.DM1.Difft $M.AED.DM1.Diff + $M.AED.IDX_PROC;
.CONST $M.AED.DM1.AED_control $M.AED.DM1.Difft + $M.AED.IDX_PROC;
.CONST $M.AED.DM1.state $M.AED.DM1.AED_control + $M.AED.IDX_PROC;
.CONST $M.AED.DM1.stateCount $M.AED.DM1.state + 1;
.CONST $M.AED.DM1.stateCountMax $M.AED.DM1.stateCount + 9;
.CONST $M.AED.DM1.noiseCount $M.AED.DM1.stateCountMax + 9;
.CONST $M.AED.DATA_SIZE_DM1 $M.AED.DM1.noiseCount + 1;



.CONST $M.TWOMIC_HF_500.OFFSET_DM1_phase_E0 $M.TWOMIC_HF_500.OFFSET_PTR_DM1data;
.CONST $M.TWOMIC_HF_500.DM1.Phase_E0 0;
.CONST $M.TWOMIC_HF_500.DM1.Phase_E1 $M.TWOMIC_HF_500.DM1.Phase_E0 + $M.BEAMFORMER.BIN_H;
.CONST $M.TWOMIC_HF_500.DATA_SIZE_DM1 $M.TWOMIC_HF_500.DM1.Phase_E1 + $M.BEAMFORMER.BIN_H;



.CONST $M.BEAMFORMER.OFFSET_DM1PTR_CC_real_imag $M.BEAMFORMER.OFFSET_PTR_DM1data;
.CONST $M.BEAMFORMER.DM1.CC_real_imag 0;
.CONST $M.BEAMFORMER.DM1.Phi_real_imag $M.BEAMFORMER.DM1.CC_real_imag + 2*$M.BEAMFORMER.PROCESSING_BINS;
.CONST $M.BEAMFORMER.DM1.TR $M.BEAMFORMER.DM1.Phi_real_imag + 2*$M.BEAMFORMER.PROCESSING_BINS;
.CONST $M.BEAMFORMER.DATA_SIZE_DM1 $M.BEAMFORMER.DM1.TR + $M.BEAMFORMER.PROCESSING_BINS;



.CONST $M.TWOCHANNEL_NC.OFFSET_DM1PTR_RcvBuf_real $M.TWOCHANNEL_NC.OFFSET_PTR_DM1data;
.CONST $M.TWOCHANNEL_NC.DM1.RcvBuf_real 0;
.CONST $M.TWOCHANNEL_NC.DM1.Gp_imag $M.TWOCHANNEL_NC.DM1.RcvBuf_real + $M.TWOCHANNEL_NC.NC_num_proc*$M.TWOCHANNEL_NC.Num_Taps;
.CONST $M.TWOCHANNEL_NC.DM1.LPwrXp $M.TWOCHANNEL_NC.DM1.Gp_imag + $M.TWOCHANNEL_NC.NC_num_proc*$M.TWOCHANNEL_NC.Num_Taps;
.CONST $M.TWOCHANNEL_NC.DM1.BExp_Gp $M.TWOCHANNEL_NC.DM1.LPwrXp + $M.TWOCHANNEL_NC.NC_num_proc;
.CONST $M.TWOCHANNEL_NC.DATA_SIZE_DM1 $M.TWOCHANNEL_NC.DM1.BExp_Gp + $M.TWOCHANNEL_NC.NC_num_proc;


.CONST $M.TWOCHANNEL_NC.OFFSET_DM2PTR_cRcvBuf_imag $M.TWOCHANNEL_NC.OFFSET_PTR_DM2data;
.CONST $M.TWOCHANNEL_NC.DM2.RcvBuf_imag 0;
.CONST $M.TWOCHANNEL_NC.DM2.Gp_real $M.TWOCHANNEL_NC.DM2.RcvBuf_imag + $M.TWOCHANNEL_NC.NC_num_proc*$M.TWOCHANNEL_NC.Num_Taps;
.CONST $M.TWOCHANNEL_NC.DM2.BExp_X_buf $M.TWOCHANNEL_NC.DM2.Gp_real + $M.TWOCHANNEL_NC.NC_num_proc*$M.TWOCHANNEL_NC.Num_Taps;
.CONST $M.TWOCHANNEL_NC.DATA_SIZE_DM2 $M.TWOCHANNEL_NC.DM2.BExp_X_buf + $M.TWOCHANNEL_NC.Num_Taps + 1;
.linefile 28 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf200/adf200_library.h" 1
.linefile 21 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf200/adf200_library.h"
.CONST $adf200_VERSION 0x020000;


.CONST $adf200.BIN_SKIPPED 9;
.CONST $adf200.ADF_num_proc 55;

.CONST $adf200.DATA_SIZE_DM1 (19 * $adf200.ADF_num_proc);
.CONST $adf200.DATA_SIZE_DM2 (13 * $adf200.ADF_num_proc);

.CONST $adf200.SCRATCH_SIZE_DM1 (5 * $adf200.ADF_num_proc);
.CONST $adf200.SCRATCH_SIZE_DM2 (1 * $adf200.ADF_num_proc);
.linefile 51 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf200/adf200_library.h"
.CONST $adf200.X0_FIELD 0;



.CONST $adf200.X1_FIELD 1;




.CONST $adf200.OFFSET_PTR_DM1data 2;



.CONST $adf200.OFFSET_PTR_DM2data 3;
.linefile 74 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf200/adf200_library.h"
.CONST $adf200.OFFSET_SCRATCH_DM1 4;




.CONST $adf200.OFFSET_SCRATCH_DM2 5;



.CONST $adf200.PTR_INTRATIO0_FIELD 6;



.CONST $adf200.PTR_INTRATIO1_FIELD 7;




.CONST $adf200.OFFSET_L_POSTP_CTRL_PTR 8;




.CONST $adf200.FUNC_APP_PREP_FIELD 9;



.CONST $adf200.FUNC_APP_PP_FIELD 10;

.CONST $adf200.OFFSET_INTERNAL_START 11;
.linefile 113 "C:/ADK3.5/kalimba/lib_sets/sdk/include/adf200/adf200_library.h"
.CONST $adf200.OFFSET_X0_REAL_PTR $adf200.OFFSET_INTERNAL_START+1;;
.CONST $adf200.OFFSET_X0_IMAG_PTR $adf200.OFFSET_X0_REAL_PTR+1;
.CONST $adf200.OFFSET_X0_EXP_PTR $adf200.OFFSET_X0_IMAG_PTR+1;
.CONST $adf200.OFFSET_X1_REAL_PTR $adf200.OFFSET_X0_EXP_PTR+1;
.CONST $adf200.OFFSET_X1_IMAG_PTR $adf200.OFFSET_X1_REAL_PTR+1;
.CONST $adf200.OFFSET_X1_EXP_PTR $adf200.OFFSET_X1_IMAG_PTR+1;
.CONST $adf200.OFFSET_Z0_REAL_PTR $adf200.OFFSET_X1_EXP_PTR+1;
.CONST $adf200.OFFSET_Z0_IMAG_PTR $adf200.OFFSET_Z0_REAL_PTR+1;
.CONST $adf200.OFFSET_Z1_REAL_PTR $adf200.OFFSET_Z0_IMAG_PTR+1;
.CONST $adf200.OFFSET_Z1_IMAG_PTR $adf200.OFFSET_Z1_REAL_PTR+1;


.CONST $adf200.OFFSET_muAt $adf200.OFFSET_Z1_IMAG_PTR+1;


.CONST $adf200.OFFSET_ct_Px0 $adf200.OFFSET_muAt+1;
.CONST $adf200.OFFSET_dL2Px0FB $adf200.OFFSET_ct_Px0+1;
.CONST $adf200.OFFSET_L2Px0t0 $adf200.OFFSET_dL2Px0FB+1;

.CONST $adf200.OFFSET_ct_Px1 $adf200.OFFSET_L2Px0t0+1;
.CONST $adf200.OFFSET_dL2Px1FB $adf200.OFFSET_ct_Px1+1;
.CONST $adf200.OFFSET_L2Px1t0 $adf200.OFFSET_dL2Px1FB+1;

.CONST $adf200.OFFSET_ct_init $adf200.OFFSET_L2Px1t0+1;

.CONST $adf200.OFFSET_ADF_LALFALPZ $adf200.OFFSET_ct_init+1;


.CONST $adf200.STRUCT_SIZE $adf200.OFFSET_ADF_LALFALPZ+1;




.CONST $MAX_24 0x7fffff;
.CONST $MIN_24 0x800000;
.CONST $MIN_48_MSB 0x800000;
.CONST $MIN_48_LSB 0;
.CONST $MAX_48_MSB 0x7fffff;
.CONST $MAX_48_LSB 0xffffff;
.linefile 29 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/mgdc100/mgdc100_library.h" 1
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/mgdc100/mgdc100_library.h"
.CONST $mgdc100.X0_FIELD 0;



.CONST $mgdc100.X1_FIELD 1;



.CONST $mgdc100.PARAM_FIELD 2;



.CONST $mgdc100.PTR_NUMFREQ_BINS_FIELD 3;



.CONST $mgdc100.PTR_G_OMS_FIELD 4;



.CONST $mgdc100.FRONTMICBIAS_FIELD 5;




.CONST $mgdc100.PTR_MICMODE_FIELD 6;



.CONST $mgdc100.PTR_OMS_VAD_FIELD 7;



.CONST $mgdc100.L2FBPXD_FIELD 8;


.CONST $mgdc100.MAXCOMP_FIELD 9;
.CONST $mgdc100.TH0_FIELD 10;
.CONST $mgdc100.TH1_FIELD 11;
.CONST $mgdc100.L2FBPX0T_FIELD 12;
.CONST $mgdc100.L2FBPX1T_FIELD 13;
.CONST $mgdc100.L2FBPXDST_FIELD 14;
.CONST $mgdc100.EXP_GAIN_FIELD 15;
.CONST $mgdc100.MTS_GAIN_FIELD 16;
.CONST $mgdc100.MEAN_OMS_G_FIELD 17;
.CONST $mgdc100.HOLD_ADAPT_FIELD 18;
.CONST $mgdc100.SWITCH_OUTPUT_FIELD 19;
.CONST $mgdc100.MGDC_UPDATE_FIELD 20;

.CONST $mgdc100.STRUC_SIZE 21;
.linefile 78 "C:/ADK3.5/kalimba/lib_sets/sdk/include/mgdc100/mgdc100_library.h"
.CONST $mgdc100.param.MAXCOMP_FIELD 0;



.CONST $mgdc100.param.TH_FIELD 1;
.linefile 30 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/nc100/nc100_library.h" 1
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/nc100/nc100_library.h"
.CONST $NC_VERSION 0x010000;





.CONST $nc100.BIN_SKIPPED 9;
.CONST $nc100.NUM_PROC 55;
.CONST $nc100.NUM_TAPS 2;
.CONST $nc100.DM1_DATA_SIZE ((2 + 2*$nc100.NUM_TAPS) * $nc100.NUM_PROC);
.CONST $nc100.DM2_DATA_SIZE ((0 + 2*$nc100.NUM_TAPS) * $nc100.NUM_PROC + $nc100.NUM_TAPS+1);
.CONST $nc100.DM1_SCRATCH_SIZE ((1 + 3*$nc100.NUM_PROC));
.linefile 35 "C:/ADK3.5/kalimba/lib_sets/sdk/include/nc100/nc100_library.h"
.CONST $nc100.X0_FIELD 0;



.CONST $nc100.X1_FIELD 1;



.CONST $nc100.DM1_DATA_FIELD 2;



.CONST $nc100.DM2_DATA_FIELD 3;



.CONST $nc100.DM1_SCRATCH_FIELD 4;




.CONST $nc100.NC_CTRL_FIELD 5;




.CONST $nc100.FUNC_APP_PREP_FIELD 6;



.CONST $nc100.FUNC_APP_PP_FIELD 7;



.CONST $nc100.RPTP_FLAG_FIELD 8;



.CONST $nc100.G_OMS_FIELD 9;




.CONST $nc100.FNLMS_FIELD 10;
.CONST $nc100.OFFSET_FNLMS_E_REAL_PTR 0 + $nc100.FNLMS_FIELD;
.CONST $nc100.OFFSET_FNLMS_E_IMAG_PTR 1 + $nc100.FNLMS_FIELD;
.CONST $nc100.OFFSET_FNLMS_D_EXP_PTR 2 + $nc100.FNLMS_FIELD;
.CONST $nc100.OFFSET_FNLMS_D_REAL_PTR 3 + $nc100.FNLMS_FIELD;
.CONST $nc100.OFFSET_FNLMS_D_IMAG_PTR 4 + $nc100.FNLMS_FIELD;

.CONST $nc100.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt 5 + $nc100.FNLMS_FIELD;
.CONST $nc100.FNLMS_END_FIELD $nc100.OFFSET_FNLMS_SCRPTR_Exp_Mts_adapt;


.CONST $nc100.STRUCT_SIZE 1 + $nc100.FNLMS_END_FIELD;
.linefile 31 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/asf100/asf100_library.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/asf100/asf100_library.h"
.CONST $asf100.BIN_SKIPPED 1;
.CONST $asf100.NUM_PROC 63;
.CONST $asf100.SCRATCH_SIZE_DM1 (6+5) * $asf100.NUM_PROC;
.CONST $asf100.SCRATCH_SIZE_DM2 (6+5) * $asf100.NUM_PROC;
.linefile 28 "C:/ADK3.5/kalimba/lib_sets/sdk/include/asf100/asf100_library.h"
.CONST $asf100.Z0_FIELD 0;



.CONST $asf100.Z1_FIELD 1;



.CONST $asf100.MODE_FIELD 2;



.CONST $asf100.PARAM_FIELD 3;



.CONST $asf100.POWER_ADJUST_FIELD 4;



.CONST $asf100.SCRATCH_DM1_FIELD 5;



.CONST $asf100.SCRATCH_DM2_FIELD 6;




.CONST $asf100.FUNC_APP_PREP_FIELD 7;




.CONST $asf100.FUNC_APP_PP_FIELD 8;



.CONST $asf100.BEAM_FUNC_FIELD 9;




.CONST $asf100.BEAM_MODE_FIELD 10;


.CONST $asf100.INTERNAL_START_FIELD 11;






.CONST $asf100.PX0N_FIELD 0 + $asf100.INTERNAL_START_FIELD;
.CONST $asf100.PX1N_FIELD 1 + $asf100.PX0N_FIELD;
.CONST $asf100.PXCRN_FIELD 1 + $asf100.PX1N_FIELD;
.CONST $asf100.PXCIN_FIELD 1 + $asf100.PXCRN_FIELD;
.CONST $asf100.COH_FIELD 1 + $asf100.PXCIN_FIELD;
.CONST $asf100.WNR_G_FIELD 1 + $asf100.COH_FIELD;
.CONST $asf100.BEAM_CC0_REAL_FIELD 1 + $asf100.WNR_G_FIELD;
.CONST $asf100.BEAM_CC0_IMAG_FIELD 1 + $asf100.BEAM_CC0_REAL_FIELD;
.CONST $asf100.BEAM_PHI0_REAL_FIELD 1 + $asf100.BEAM_CC0_IMAG_FIELD;
.CONST $asf100.BEAM_PHI0_IMAG_FIELD 1 + $asf100.BEAM_PHI0_REAL_FIELD;
.CONST $asf100.BEAM_FD_W0_REAL_FIELD 1 + $asf100.BEAM_PHI0_IMAG_FIELD;
.CONST $asf100.BEAM_FD_W0_IMAG_FIELD 1 + $asf100.BEAM_FD_W0_REAL_FIELD;
.CONST $asf100.BEAM_FD_W1_REAL_FIELD 1 + $asf100.BEAM_FD_W0_IMAG_FIELD;
.CONST $asf100.BEAM_FD_W1_IMAG_FIELD 1 + $asf100.BEAM_FD_W1_REAL_FIELD;
.CONST $asf100.BEAM_FW_W1_REAL_FIELD 1 + $asf100.BEAM_FD_W1_IMAG_FIELD;
.CONST $asf100.BEAM_FW_W1_IMAG_FIELD 1 + $asf100.BEAM_FW_W1_REAL_FIELD;
.CONST $asf100.BEAM_COMP_T_REAL_FIELD 1 + $asf100.BEAM_FW_W1_IMAG_FIELD;
.CONST $asf100.BEAM_COMP_T_IMAG_FIELD 1 + $asf100.BEAM_COMP_T_REAL_FIELD;
.CONST $asf100.BEAM_TR0_FIELD 1 + $asf100.BEAM_COMP_T_IMAG_FIELD;
.CONST $asf100.BEAM_TR1_FIELD 1 + $asf100.BEAM_TR0_FIELD;
.CONST $asf100.COH_COS_FIELD 1 + $asf100.BEAM_TR1_FIELD;
.CONST $asf100.COH_SIN_FIELD 1 + $asf100.COH_COS_FIELD;
.CONST $asf100.COH_G_FIELD 1 + $asf100.COH_SIN_FIELD;

.CONST $asf100.X0_REAL_FIELD 1 + $asf100.COH_G_FIELD;
.CONST $asf100.X0_IMAG_FIELD 1 + $asf100.X0_REAL_FIELD;
.CONST $asf100.X0_BEXP_FIELD 1 + $asf100.X0_IMAG_FIELD;
.CONST $asf100.X1_REAL_FIELD 1 + $asf100.X0_BEXP_FIELD;
.CONST $asf100.X1_IMAG_FIELD 1 + $asf100.X1_REAL_FIELD;
.CONST $asf100.X1_BEXP_FIELD 1 + $asf100.X1_IMAG_FIELD;
.CONST $asf100.X0_SAVED_REAL_FIELD 1 + $asf100.X1_BEXP_FIELD;
.CONST $asf100.X0_SAVED_IMAG_FIELD 1 + $asf100.X0_SAVED_REAL_FIELD;
.CONST $asf100.X0_SAVED_BEXP_FIELD 1 + $asf100.X0_SAVED_IMAG_FIELD;


.CONST $asf100.COH_IMAG_FIELD 1 + $asf100.X0_SAVED_BEXP_FIELD;



.CONST $asf100.SCRATCH_PXCRNT_FIELD 1 + $asf100.COH_IMAG_FIELD;
.CONST $asf100.SCRATCH_PXCINT_FIELD 1 + $asf100.SCRATCH_PXCRNT_FIELD;
.CONST $asf100.SCRATCH_PX0NT_FIELD 1 + $asf100.SCRATCH_PXCINT_FIELD;
.CONST $asf100.SCRATCH_PX1NT_FIELD 1 + $asf100.SCRATCH_PX0NT_FIELD;

.CONST $asf100.SCRATCH_LPX0T_FIELD 1 + $asf100.SCRATCH_PX1NT_FIELD;
.CONST $asf100.SCRATCH_LPX1T_FIELD 1 + $asf100.SCRATCH_LPX0T_FIELD;


.CONST $asf100.BYPASS_FLAG_WNR_FIELD 1 + $asf100.SCRATCH_LPX1T_FIELD;
.CONST $asf100.BYPASS_FLAG_COH_FIELD 1 + $asf100.BYPASS_FLAG_WNR_FIELD;
.CONST $asf100.BYPASS_FLAG_BF_FIELD 1 + $asf100.BYPASS_FLAG_COH_FIELD;




.CONST $asf100.wnr.G1_FIELD 1 + $asf100.BYPASS_FLAG_BF_FIELD;
.CONST $asf100.wnr.PHS_FACTOR_EXP_FIELD 1 + $asf100.wnr.G1_FIELD;
.CONST $asf100.wnr.PHS_FACTOR_LB_FIELD 1 + $asf100.wnr.PHS_FACTOR_EXP_FIELD;
.CONST $asf100.wnr.PHS_FACTOR_TR_FIELD 1 + $asf100.wnr.PHS_FACTOR_LB_FIELD;
.CONST $asf100.wnr.PHS_FACTOR_HB_FIELD 1 + $asf100.wnr.PHS_FACTOR_TR_FIELD;
.CONST $asf100.wnr.MEAN_PWR_FIELD 1 + $asf100.wnr.PHS_FACTOR_HB_FIELD;
.CONST $asf100.wnr.MEAN_G_FIELD 1 + $asf100.wnr.MEAN_PWR_FIELD;
.CONST $asf100.wnr.MEAN_CC0_FIELD 1 + $asf100.wnr.MEAN_G_FIELD;
.CONST $asf100.wnr.COH_ATK_FIELD 1 + $asf100.wnr.MEAN_CC0_FIELD;
.CONST $asf100.wnr.COH_DEC_FIELD 1 + $asf100.wnr.COH_ATK_FIELD;
.CONST $asf100.wnr.DETECT_FLAG_FIELD 1 + $asf100.wnr.COH_DEC_FIELD;
.CONST $asf100.wnr.COHERENCE_FIELD 1 + $asf100.wnr.DETECT_FLAG_FIELD;
.CONST $asf100.wnr.WIND_FIELD 1 + $asf100.wnr.COHERENCE_FIELD;
.CONST $asf100.WNROBJ_END_FIELD 0 + $asf100.wnr.WIND_FIELD;
.linefile 160 "C:/ADK3.5/kalimba/lib_sets/sdk/include/asf100/asf100_library.h"
.CONST $asf100.bf.SCRATCH_W0_REAL_FIELD 1 + $asf100.WNROBJ_END_FIELD;
.CONST $asf100.bf.SCRATCH_W0_IMAG_FIELD 1 + $asf100.bf.SCRATCH_W0_REAL_FIELD;
.CONST $asf100.bf.SCRATCH_W1_REAL_FIELD 1 + $asf100.bf.SCRATCH_W0_IMAG_FIELD;
.CONST $asf100.bf.SCRATCH_W1_IMAG_FIELD 1 + $asf100.bf.SCRATCH_W1_REAL_FIELD;
.CONST $asf100.bf.SCRATCH_Z0_FDSB_REAL_FIELD 1 + $asf100.bf.SCRATCH_W1_IMAG_FIELD;
.CONST $asf100.bf.SCRATCH_Z0_FDSB_IMAG_FIELD 1 + $asf100.bf.SCRATCH_Z0_FDSB_REAL_FIELD;
.CONST $asf100.bf.SCRATCH_BEXP_Z0_FDSB_FIELD 1 + $asf100.bf.SCRATCH_Z0_FDSB_IMAG_FIELD;

.CONST $asf100.bf.SCRATCH_PS0T_FIELD 1 + $asf100.bf.SCRATCH_BEXP_Z0_FDSB_FIELD;
.CONST $asf100.bf.SCRATCH_NPX0_FIELD 1 + $asf100.bf.SCRATCH_PS0T_FIELD;
.CONST $asf100.bf.SCRATCH_PS1T_FIELD 1 + $asf100.bf.SCRATCH_NPX0_FIELD;
.CONST $asf100.bf.SCRATCH_NEG_D_FIELD 1 + $asf100.bf.SCRATCH_PS1T_FIELD;
.CONST $asf100.bf.BEAM_FW_W0_REAL_FIELD 1 + $asf100.bf.SCRATCH_NEG_D_FIELD;
.CONST $asf100.bf.BEAM_TEMP_FIELD 1 + $asf100.bf.BEAM_FW_W0_REAL_FIELD;
.CONST $asf100.BF_END_FIELD 0 + $asf100.bf.BEAM_TEMP_FIELD;


.CONST $asf100.STRUC_SIZE 1 + $asf100.BF_END_FIELD;
.linefile 190 "C:/ADK3.5/kalimba/lib_sets/sdk/include/asf100/asf100_library.h"
.CONST $asf100.param.MIC_DIST_FIELD 0;




.CONST $asf100.wnr.param.GAIN_AGGR_FIELD 1;




.CONST $asf100.wnr.param.THRESH_SILENCE_FIELD 2;



.CONST $asf100.bf.param.BETA0_FIELD 3;



.CONST $asf100.bf.param.BETA1_FIELD 4;



.CONST $asf100.wnr.param.THRESH_PHASE_FIELD 5;



.CONST $asf100.wnr.param.THRESH_COHERENCE_FIELD 6;
.linefile 32 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/dmss/dmss_library.h" 1
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/dmss/dmss_library.h"
.CONST $dmss.X0_FIELD 0;



.CONST $dmss.X1_FIELD 1;



.CONST $dmss.PTR_NUMBIN_FIELD 2;

.CONST $dmss.INTERNAL_START_FIELD 3;


.CONST $dmss.LPIN0_FIELD 0 + $dmss.INTERNAL_START_FIELD;
.CONST $dmss.LPIN1_FIELD 1 + $dmss.LPIN0_FIELD;
.CONST $dmss.LPOUT0_FIELD 1 + $dmss.LPIN1_FIELD;
.CONST $dmss.LPOUT1_FIELD 1 + $dmss.LPOUT0_FIELD;
.CONST $dmss.DIFF_LP_FIELD 1 + $dmss.LPOUT1_FIELD;

.CONST $dmss.STRUC_SIZE 1 + $dmss.DIFF_LP_FIELD;;







.CONST $dmss100.BIN_SKIPPED 1;
.CONST $dmss100.NUM_PROC 63;
.CONST $dmss.LP_INIT (-48<<16);
.CONST $dmss.LALFALPZ -5.64371240507421220/(1<<7);
.linefile 33 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_modules.h" 2
.linefile 37 "send_proc.asm" 2
.linefile 1 "a2dp_low_latency_2mic.h" 1
.linefile 11 "a2dp_low_latency_2mic.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/a2dp_low_latency_2mic_config.h" 1
.linefile 12 "a2dp_low_latency_2mic.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/a2dp_low_latency_2mic_library_gen.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/a2dp_low_latency_2mic_library_gen.h"
.CONST $A2DP_LOW_LATENCY_2MIC_SYSID 0xE103;


.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.SPKR_EQ_BYPASS 0x000400;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.EQFLAT 0x000200;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.USER_EQ_BYPASS 0x000100;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BASS_BOOST_BYPASS 0x000080;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.SPATIAL_BYPASS 0x000040;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.COMPANDER_BYPASS 0x000020;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.DITHER_BYPASS 0x000010;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.USER_EQ_SELECT 0x000007;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.CNGENA 0x200000;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_SNDAGC 0x000800;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.SIDETONEENA 0x002000;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.RERENA 0x000004;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.AECENA 0x000002;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.HDBYP 0x001000;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_AGCPERSIST 0x008000;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_MGDC 0x000002;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_SPP 0x000040;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_GSMOOTH 0x000080;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_NFLOOR 0x000100;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.GSCHEME 0x000200;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.DMSS_MODE 0x000001;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_ADF 0x000008;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_NC 0x000010;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_WNR 0x000004;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_DMS 0x000020;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_MGDCPERSIST 0x000400;


.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CUR_MODE_OFFSET 0;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.SYSCONTROL_OFFSET 1;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.FUNC_MIPS_OFFSET 2;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.DECODER_MIPS_OFFSET 3;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_PCMINL_OFFSET 4;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_PCMINR_OFFSET 5;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_DACL_OFFSET 6;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_DACR_OFFSET 7;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_SUB_OFFSET 8;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CUR_DACL_OFFSET 9;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.USER_EQ_BANK_OFFSET 10;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CONFIG_FLAG_OFFSET 11;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.DELAY 12;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_TYPE_OFFSET 13;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_FS_OFFSET 14;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_CHANNEL_MODE 15;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_STAT1 16;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_STAT2 17;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_STAT3 18;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_STAT4 19;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_STAT5 20;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.INTERFACE_TYPE 21;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.INPUT_RATE 22;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.OUTPUT_RATE 23;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CODEC_RATE 24;

.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CALL_STATE_OFFSET 25;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.SEC_STAT_OFFSET 26;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_ADC_LEFT_OFFSET 27;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_ADC_RIGHT_OFFSET 28;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_SCO_OUT_OFFSET 29;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_MIPS_OFFSET 30;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_AUX_OFFSET 31;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.CONNSTAT 32;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.SIDETONE_GAIN 33;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.VOLUME 34;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.PEAK_SIDETONE 35;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.SND_AGC_SPEECH_LVL 36;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.SND_AGC_GAIN 37;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.AEC_COUPLING_OFFSET 38;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.WNR_POWER 39;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.WNR_WIND_PHASE 40;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.WIND_FLAG 41;
.CONST $M.A2DP_LOW_LATENCY_2MIC.STATUS.BLOCK_SIZE 42;


.CONST $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.STANDBY 0;
.CONST $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.PSTHRGH_LEFT 1;
.CONST $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.PSTHRGH_RIGHT 2;
.CONST $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC 3;
.CONST $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.LOWVOLUME 4;
.CONST $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.MAX_MODES 5;


.CONST $M.A2DP_LOW_LATENCY_2MIC.CONTROL.DAC_OVERRIDE 0x8000;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONTROL.CALLSTATE_OVERRIDE 0x4000;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CONTROL.MODE_OVERRIDE 0x2000;


.CONST $M.A2DP_LOW_LATENCY_2MIC.INTERFACE.ANALOG 0;
.CONST $M.A2DP_LOW_LATENCY_2MIC.INTERFACE.I2S 1;


.CONST $M.A2DP_LOW_LATENCY_2MIC.CALLST.MUTE 0;
.CONST $M.A2DP_LOW_LATENCY_2MIC.CALLST.CONNECTED 1;


.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG 0;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_CONFIG 1;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_GAIN_EXP 2;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_GAIN_MANT 3;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B2 4;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B1 5;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B0 6;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_A2 7;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_A1 8;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B2 9;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B1 10;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B0 11;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_A2 12;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_A1 13;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B2 14;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B1 15;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B0 16;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_A2 17;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_A1 18;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B2 19;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B1 20;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B0 21;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_A2 22;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_A1 23;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B2 24;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B1 25;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B0 26;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_A2 27;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_A1 28;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE1 29;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE2 30;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE3 31;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE4 32;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE5 33;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_CONFIG 34;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_GAIN_EXP 35;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_GAIN_MANT 36;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B2 37;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B1 38;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B0 39;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_A2 40;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_A1 41;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B2 42;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B1 43;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B0 44;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_A2 45;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_A1 46;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B2 47;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B1 48;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B0 49;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_A2 50;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_A1 51;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B2 52;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B1 53;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B0 54;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_A2 55;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_A1 56;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B2 57;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B1 58;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B0 59;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_A2 60;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_A1 61;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE1 62;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE2 63;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE3 64;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE4 65;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE5 66;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_CONFIG 67;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_GAIN_EXP 68;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_GAIN_MANT 69;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_B2 70;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_B1 71;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_B0 72;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_A2 73;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_A1 74;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ1_SCALE 75;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_CONFIG 76;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_GAIN_EXP 77;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_GAIN_MANT 78;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_B2 79;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_B1 80;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_B0 81;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_A2 82;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_A1 83;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BOOST_EQ2_SCALE 84;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_CONFIG 85;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_GAIN_EXP 86;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_GAIN_MANT 87;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_B2 88;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_B1 89;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_B0 90;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_A2 91;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_A1 92;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_B2 93;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_B1 94;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_B0 95;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_A2 96;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_A1 97;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_B2 98;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_B1 99;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_B0 100;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_A2 101;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_A1 102;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_B2 103;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_B1 104;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_B0 105;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_A2 106;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_A1 107;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_B2 108;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_B1 109;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_B0 110;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_A2 111;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_A1 112;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE1 113;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE2 114;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE3 115;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE4 116;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE5 117;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_CONFIG 118;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_GAIN_EXP 119;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_GAIN_MANT 120;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_B2 121;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_B1 122;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_B0 123;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_A2 124;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_A1 125;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_B2 126;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_B1 127;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_B0 128;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_A2 129;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_A1 130;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_B2 131;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_B1 132;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_B0 133;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_A2 134;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_A1 135;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_B2 136;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_B1 137;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_B0 138;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_A2 139;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_A1 140;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_B2 141;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_B1 142;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_B0 143;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_A2 144;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_A1 145;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE1 146;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE2 147;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE3 148;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE4 149;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE5 150;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_CONFIG 151;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_GAIN_EXP 152;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_GAIN_MANT 153;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_B2 154;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_B1 155;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_B0 156;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_A2 157;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_A1 158;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_B2 159;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_B1 160;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_B0 161;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_A2 162;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_A1 163;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_B2 164;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_B1 165;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_B0 166;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_A2 167;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_A1 168;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_B2 169;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_B1 170;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_B0 171;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_A2 172;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_A1 173;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_B2 174;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_B1 175;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_B0 176;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_A2 177;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_A1 178;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE1 179;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE2 180;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE3 181;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE4 182;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE5 183;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_CONFIG 184;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_GAIN_EXP 185;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_GAIN_MANT 186;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_B2 187;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_B1 188;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_B0 189;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_A2 190;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_A1 191;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_B2 192;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_B1 193;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_B0 194;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_A2 195;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_A1 196;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_B2 197;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_B1 198;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_B0 199;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_A2 200;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_A1 201;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_B2 202;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_B1 203;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_B0 204;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_A2 205;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_A1 206;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_B2 207;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_B1 208;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_B0 209;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_A2 210;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_A1 211;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE1 212;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE2 213;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE3 214;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE4 215;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE5 216;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_CONFIG 217;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_GAIN_EXP 218;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_GAIN_MANT 219;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_B2 220;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_B1 221;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_B0 222;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_A2 223;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_A1 224;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_B2 225;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_B1 226;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_B0 227;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_A2 228;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_A1 229;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_B2 230;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_B1 231;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_B0 232;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_A2 233;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_A1 234;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_B2 235;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_B1 236;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_B0 237;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_A2 238;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_A1 239;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_B2 240;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_B1 241;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_B0 242;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_A2 243;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_A1 244;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE1 245;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE2 246;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE3 247;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE4 248;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE5 249;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_CONFIG 250;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_GAIN_EXP 251;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_GAIN_MANT 252;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_B2 253;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_B1 254;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_B0 255;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_A2 256;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_A1 257;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_B2 258;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_B1 259;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_B0 260;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_A2 261;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_A1 262;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_B2 263;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_B1 264;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_B0 265;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_A2 266;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_A1 267;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_B2 268;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_B1 269;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_B0 270;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_A2 271;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_A1 272;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_B2 273;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_B1 274;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_B0 275;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_A2 276;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_A1 277;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE1 278;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE2 279;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE3 280;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE4 281;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE5 282;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_CONFIG 283;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_GAIN_EXP 284;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_GAIN_MANT 285;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_B2 286;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_B1 287;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_B0 288;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_A2 289;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_A1 290;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_B2 291;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_B1 292;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_B0 293;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_A2 294;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_A1 295;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_B2 296;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_B1 297;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_B0 298;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_A2 299;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_A1 300;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_B2 301;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_B1 302;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_B0 303;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_A2 304;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_A1 305;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_B2 306;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_B1 307;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_B0 308;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_A2 309;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_A1 310;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE1 311;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE2 312;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE3 313;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE4 314;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE5 315;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_CONFIG 316;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_GAIN_EXP 317;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_GAIN_MANT 318;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_B2 319;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_B1 320;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_B0 321;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_A2 322;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_A1 323;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_B2 324;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_B1 325;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_B0 326;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_A2 327;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_A1 328;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_B2 329;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_B1 330;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_B0 331;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_A2 332;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_A1 333;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_B2 334;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_B1 335;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_B0 336;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_A2 337;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_A1 338;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_B2 339;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_B1 340;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_B0 341;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_A2 342;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_A1 343;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE1 344;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE2 345;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE3 346;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE4 347;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE5 348;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_CONFIG 349;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_GAIN_EXP 350;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_GAIN_MANT 351;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_B2 352;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_B1 353;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_B0 354;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_A2 355;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_A1 356;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_B2 357;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_B1 358;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_B0 359;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_A2 360;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_A1 361;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_B2 362;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_B1 363;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_B0 364;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_A2 365;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_A1 366;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_B2 367;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_B1 368;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_B0 369;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_A2 370;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_A1 371;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_B2 372;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_B1 373;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_B0 374;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_A2 375;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_A1 376;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE1 377;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE2 378;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE3 379;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE4 380;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE5 381;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_CONFIG 382;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_GAIN_EXP 383;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_GAIN_MANT 384;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_B2 385;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_B1 386;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_B0 387;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_A2 388;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_A1 389;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_B2 390;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_B1 391;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_B0 392;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_A2 393;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_A1 394;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_B2 395;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_B1 396;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_B0 397;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_A2 398;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_A1 399;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_B2 400;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_B1 401;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_B0 402;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_A2 403;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_A1 404;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_B2 405;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_B1 406;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_B0 407;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_A2 408;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_A1 409;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE1 410;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE2 411;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE3 412;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE4 413;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE5 414;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_CONFIG 415;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_GAIN_EXP 416;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_GAIN_MANT 417;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_B2 418;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_B1 419;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_B0 420;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_A2 421;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_A1 422;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_B2 423;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_B1 424;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_B0 425;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_A2 426;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_A1 427;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_B2 428;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_B1 429;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_B0 430;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_A2 431;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_A1 432;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_B2 433;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_B1 434;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_B0 435;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_A2 436;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_A1 437;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_B2 438;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_B1 439;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_B0 440;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_A2 441;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_A1 442;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE1 443;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE2 444;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE3 445;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE4 446;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE5 447;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_CONFIG 448;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_GAIN_EXP 449;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_GAIN_MANT 450;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_B2 451;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_B1 452;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_B0 453;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_A2 454;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_A1 455;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_B2 456;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_B1 457;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_B0 458;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_A2 459;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_A1 460;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_B2 461;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_B1 462;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_B0 463;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_A2 464;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_A1 465;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_B2 466;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_B1 467;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_B0 468;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_A2 469;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_A1 470;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_B2 471;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_B1 472;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_B0 473;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_A2 474;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_A1 475;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE1 476;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE2 477;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE3 478;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE4 479;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE5 480;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MAX_USER_EQ_BANKS 481;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SDICONFIG 482;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DAC_GAIN_L 483;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DAC_GAIN_R 484;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TABLE_SIZE 485;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE0 486;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE1 487;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE2 488;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE3 489;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE4 490;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE5 491;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE6 492;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE7 493;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE8 494;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE9 495;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE10 496;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE11 497;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE12 498;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE13 499;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE14 500;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE15 501;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE16 502;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE0 503;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE1 504;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE2 505;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE3 506;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE4 507;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE5 508;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE6 509;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE7 510;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE8 511;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE9 512;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE10 513;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE11 514;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE12 515;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE13 516;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE14 517;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE15 518;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE16 519;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE_SIZE 520;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE0 521;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE1 522;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE2 523;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE3 524;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE4 525;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE5 526;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE6 527;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BASS_MANAGER_CONFIG 528;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A1 529;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A2 530;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A3 531;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A4 532;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A5 533;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_FREQ 534;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_REFLECTION_DELAY 535;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SE_MIX 536;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD1 537;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD1 538;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD1 539;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD1 540;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO1 541;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO1 542;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO1 543;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO1 544;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC1 545;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC1 546;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC1 547;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC1 548;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC1 549;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC1 550;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC1 551;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC1 552;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MAKEUP_GAIN1 553;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD2 554;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD2 555;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD2 556;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD2 557;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO2 558;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO2 559;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO2 560;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO2 561;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC2 562;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC2 563;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC2 564;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC2 565;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC2 566;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC2 567;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC2 568;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC2 569;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MAKEUP_GAIN2 570;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SIGNAL_DETECT_THRESH 571;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SIGNAL_DETECT_TIMEOUT 572;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE 573;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC1_CONFIG 574;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC2_CONFIG 575;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC3_CONFIG 576;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC4_CONFIG 577;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC5_CONFIG 578;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC6_CONFIG 579;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC7_CONFIG 580;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC8_CONFIG 581;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC9_CONFIG 582;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC10_CONFIG 583;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG 584;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ADC_GAIN_LEFT 585;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ADC_GAIN_RIGHT 586;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_CONFIG 587;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_GAIN_EXP 588;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_GAIN_MANT 589;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B2 590;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B1 591;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B0 592;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_A2 593;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_A1 594;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B2 595;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B1 596;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B0 597;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_A2 598;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_A1 599;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B2 600;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B1 601;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B0 602;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_A2 603;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_A1 604;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B2 605;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B1 606;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B0 607;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_A2 608;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_A1 609;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B2 610;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B1 611;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B0 612;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_A2 613;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_A1 614;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE1 615;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE2 616;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE3 617;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE4 618;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE5 619;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE 620;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE1 621;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE2 622;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE3 623;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE4 624;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE5 625;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE6 626;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE7 627;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE8 628;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE9 629;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE10 630;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE11 631;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE12 632;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE13 633;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE14 634;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE15 635;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_CLIP_POINT 636;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_ADJUST_LIMIT 637;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_STF_SWITCH 638;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_STF_NOISE_LOW_THRES 639;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_STF_NOISE_HIGH_THRES 640;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_STF_GAIN_EXP 641;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_STF_GAIN_MANTISSA 642;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_CONFIG 643;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_GAIN_EXP 644;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_GAIN_MANT 645;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_B2 646;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_B1 647;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_B0 648;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_A2 649;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_A1 650;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_B2 651;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_B1 652;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_B0 653;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_A2 654;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_A1 655;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_B2 656;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_B1 657;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_B0 658;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_A2 659;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_A1 660;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_SCALE1 661;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_SCALE2 662;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ST_PEQ_SCALE3 663;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SNDGAIN_MANTISSA 664;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SNDGAIN_EXPONENT 665;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA 666;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT 667;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_G_INITIAL 668;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_TARGET 669;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_ATTACK_TC 670;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_DECAY_TC 671;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_A_90_PK 672;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_D_90_PK 673;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_G_MAX 674;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_START_COMP 675;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_COMP 676;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_INP_THRESH 677;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_SP_ATTACK 678;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_AD_THRESH1 679;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_AD_THRESH2 680;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_G_MIN 681;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME 682;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_NOISE_HOLD_TIME 683;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC 684;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_DECAY_TC 685;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_ENVELOPE_TC 686;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_INIT_FRAME_THRESH 687;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_RATIO 688;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_MIN_SIGNAL 689;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_MIN_MAX_ENVELOPE 690;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_DELTA_THRESHOLD 691;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_COUNT_THRESHOLD 692;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ENABLE_AEC_REUSE 693;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_LPN_MIC 694;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG 695;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ASF_MIC_DISTANCE 696;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ASF_WNR_AGGR 697;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ASF_WNR_THRESHOLD 698;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ASF_BETA0 699;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ASF_BETA1 700;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_WNR_THRESH_PHASE 701;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_WNR_THRESH_COHERENCE 702;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MGDC_MAXCOMP 703;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MGDC_TH 704;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ASR_OMS_AGGR 705;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMS_AGGR 706;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RESIDUAL_NFLOOR 707;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LVMODE_THRES 708;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_REF_DELAY 709;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ADCGAIN_SSR 710;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CNG_Q 711;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CNG_SHAPE 712;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DTC_AGGR 713;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HD_THRESH_GAIN 714;

.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_0 715;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_1 716;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_2 717;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_3 718;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_4 719;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_5 720;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_6 721;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_7 722;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_8 723;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DSP_USER_9 724;
.CONST $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.STRUCT_SIZE 725;
.linefile 13 "a2dp_low_latency_2mic.h" 2

.CONST $AUDIO_IF_MASK (0x00ff);
.CONST $LOCAL_PLAYBACK_MASK (0x0100);

.CONST $cmpd100.OFFSET_CONTROL_WORD 0;
.CONST $cmpd100.OFFSET_ENABLE_BIT_MASK 1;
.CONST $cmpd100.OFFSET_INPUT_CH1_PTR 2;
.CONST $cmpd100.OFFSET_INPUT_CH2_PTR 3;
.CONST $cmpd100.OFFSET_OUTPUT_CH1_PTR 4;
.CONST $cmpd100.OFFSET_OUTPUT_CH2_PTR 5;
.CONST $cmpd100.OFFSET_MAKEUP_GAIN 6;
.CONST $cmpd100.OFFSET_GAIN_PTR 7;
.CONST $cmpd100.OFFSET_NEG_ONE 8;
.CONST $cmpd100.OFFSET_POW2_NEG4 9;
.CONST $cmpd100.OFFSET_EXPAND_THRESHOLD 10;
.CONST $cmpd100.OFFSET_LINEAR_THRESHOLD 11;
.CONST $cmpd100.OFFSET_COMPRESS_THRESHOLD 12;
.CONST $cmpd100.OFFSET_LIMIT_THRESHOLD 13;
.CONST $cmpd100.OFFSET_INV_EXPAND_RATIO 14;
.CONST $cmpd100.OFFSET_INV_LINEAR_RATIO 15;
.CONST $cmpd100.OFFSET_INV_COMPRESS_RATIO 16;
.CONST $cmpd100.OFFSET_INV_LIMIT_RATIO 17;
.CONST $cmpd100.OFFSET_EXPAND_CONSTANT 18;
.CONST $cmpd100.OFFSET_LINEAR_CONSTANT 19;
.CONST $cmpd100.OFFSET_COMPRESS_CONSTANT 20;
.CONST $cmpd100.OFFSET_EXPAND_ATTACK_TC 21;
.CONST $cmpd100.OFFSET_EXPAND_DECAY_TC 22;
.CONST $cmpd100.OFFSET_LINEAR_ATTACK_TC 23;
.CONST $cmpd100.OFFSET_LINEAR_DECAY_TC 24;
.CONST $cmpd100.OFFSET_COMPRESS_ATTACK_TC 25;
.CONST $cmpd100.OFFSET_COMPRESS_DECAY_TC 26;
.CONST $cmpd100.OFFSET_LIMIT_ATTACK_TC 27;
.CONST $cmpd100.OFFSET_LIMIT_DECAY_TC 28;
.CONST $cmpd100.OFFSET_HEADROOM_COMPENSATION 29;
.CONST $cmpd100.STRUC_SIZE 30;


.CONST $INVALID_IO -1;
.CONST $FASTSTREAM_IO 4;
.CONST $APTX_ACL_SPRINT_IO 7;


.CONST $FASTSTREAM_CODEC_CONFIG $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC1_CONFIG;
.CONST $APTX_ACL_SPRINT_CODEC_CONFIG $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CODEC2_CONFIG;


.CONST $FASTSTREAM_CODEC_TYPE 0;
.CONST $APTX_ACL_SPRINT_CODEC_TYPE 1;






.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/flash.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/flash.h"
   .CONST $PM_FLASHWIN_SIZE_MAX 0x40000;




   .CONST $flash.get_file_address.MAX_HANDLERS 10;


   .CONST $flash.get_file_address.NEXT_ENTRY_FIELD 0;
   .CONST $flash.get_file_address.FILE_ID_FIELD 1;
   .CONST $flash.get_file_address.HANDLER_ADDR_FIELD 2;
   .CONST $flash.get_file_address.STRUC_SIZE 3;

   .CONST $flash.get_file_address.LAST_ENTRY -1;
   .CONST $flash.get_file_address.REATTEMPT_TIME_PERIOD 10000;

   .CONST $flash.get_file_address.MESSAGE_HANDLER_UNINITIALISED -1;
.linefile 68 "a2dp_low_latency_2mic.h" 2

.CONST $CVC.BW.PARAM.SYS_FS 0;
.CONST $CVC.BW.PARAM.Num_Samples_Per_Frame 1;
.CONST $CVC.BW.PARAM.Num_FFT_Freq_Bins 2;
.CONST $CVC.BW.PARAM.Num_FFT_Window 3;

.CONST $CVC.BW.PARAM.OMS_MODE_OBJECT 5;
.CONST $CVC.BW.PARAM.AEC_LPWRX_MARGIN_OVFL 6;
.CONST $CVC.BW.PARAM.AEC_LPWRX_MARGIN_SCL 7;
.CONST $CVC.BW.PARAM.AEC_PTR_NZ_TABLES 8;
.CONST $CVC.BW.PARAM.VAD_PEQ_PARAM_PTR 9;
.CONST $CVC.BW.PARAM.DCBLOC_PEQ_PARAM_PTR 10;
.CONST $CVC.BW.PARAM.FB_CONFIG_RCV_ANALYSIS 11;
.CONST $CVC.BW.PARAM.FB_CONFIG_RCV_SYNTHESIS 12;
.CONST $CVC.BW.PARAM.FB_CONFIG_AEC 13;

.CONST $CVC.BW.PARAM.BANDWIDTDH_ID 14;
.CONST $CVC.BW.PARAM.ASF_MODE 15;
.CONST $CVC.BW.PARAM.DMS_MODE 16;
.CONST $M.CVC.vad_hold.PTR_VAD_FLAG_FIELD 0;
.CONST $M.CVC.vad_hold.PTR_EVENT_FLAG_FIELD 1;
.CONST $M.CVC.vad_hold.FLAG_FIELD 2;
.CONST $M.CVC.vad_hold.PTR_HOLD_TIME_FRAMES_FIELD 3;
.CONST $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD 4;
.CONST $M.CVC.vad_hold.STRUC_SIZE 5;
.linefile 115 "a2dp_low_latency_2mic.h"
   .CONST $M.CVC.Num_FFT_Freq_Bins 129;
   .CONST $M.CVC.Num_Samples_Per_Frame 120;
   .CONST $M.CVC.Num_FFT_Window 240;
   .CONST $M.CVC.DAC_Num_Samples_Per_Frame $M.CVC.Num_Samples_Per_Frame;
   .CONST $M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY ($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame);
   .CONST $SAMPLE_RATE_DAC 16000;
   .CONST $SAMPLE_RATE 16000;
   .CONST $BLOCK_SIZE_ADC_DAC 120;
   .CONST $M.oms270.FFT_NUM_BIN $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.oms270.STATE_LENGTH $M.oms270.wide_band.STATE_LENGTH;
   .CONST $M.oms270.SCRATCH_LENGTH $M.oms270.wide_band.SCRATCH_LENGTH;
.linefile 161 "a2dp_low_latency_2mic.h"
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.DMSS_MODE $M.A2DP_LOW_LATENCY_2MIC.CONFIG.DMSS_MODE;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_MGDC $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_MGDC;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_WNR $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_WNR;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_ADF $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_ADF;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_NC $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_NC;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_DMS $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_DMS;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_SPP $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_SPP;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_NFLOOR $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_NFLOOR;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_GSMOOTH $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_GSMOOTH;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.GSCHEME $M.A2DP_LOW_LATENCY_2MIC.CONFIG.GSCHEME;
.CONST $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_MGDCPERSIST $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_MGDCPERSIST;
.linefile 38 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_system_library.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_system_library.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/delay.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/delay.h"
   .CONST $audio_proc.delay.INPUT_ADDR_FIELD 0;

   .CONST $audio_proc.delay.OUTPUT_ADDR_FIELD 1;


   .CONST $audio_proc.delay.DBUFF_ADDR_FIELD 2;

   .CONST $audio_proc.delay.DELAY_FIELD 3;

   .CONST $audio_proc.delay.STRUC_SIZE 4;
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/peq.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/peak_monitor.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/peak_monitor.h"
   .CONST $M.audio_proc.peak_monitor.PTR_INPUT_BUFFER_FIELD 0;
   .CONST $M.audio_proc.peak_monitor.PEAK_LEVEL 1;
   .CONST $M.audio_proc.peak_monitor.STRUCT_SIZE 2;
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stream_gain.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stream_gain.h"
.CONST $M.audio_proc.stream_gain.OFFSET_INPUT_PTR 0;
.CONST $M.audio_proc.stream_gain.OFFSET_OUTPUT_PTR 1;
.CONST $M.audio_proc.stream_gain.OFFSET_PTR_MANTISSA 2;
.CONST $M.audio_proc.stream_gain.OFFSET_PTR_EXPONENT 3;
.CONST $M.audio_proc.stream_gain.STRUC_SIZE 4;

.CONST $audio_proc.stream_gain_ramp.RAMP_STEP_FIELD 0;
.CONST $audio_proc.stream_gain_ramp.RAMP_GAIN_FIELD 1;
.CONST $audio_proc.stream_gain_ramp.PREV_MANTISSA_FIELD 2;
.CONST $audio_proc.stream_gain_ramp.PREV_EXPONENT_FIELD 3;
.CONST $audio_proc.stream_gain_ramp.STRUC_SIZE 4;
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stream_mixer.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stream_mixer.h"
.CONST $M.audio_proc.stream_mixer.OFFSET_INPUT_CH1_PTR 0;
.CONST $M.audio_proc.stream_mixer.OFFSET_INPUT_CH2_PTR 1;
.CONST $M.audio_proc.stream_mixer.OFFSET_OUTPUT_PTR 2;
.CONST $M.audio_proc.stream_mixer.OFFSET_PTR_CH1_MANTISSA 3;
.CONST $M.audio_proc.stream_mixer.OFFSET_PTR_CH2_MANTISSA 4;
.CONST $M.audio_proc.stream_mixer.OFFSET_PTR_EXPONENT 5;
.CONST $M.audio_proc.stream_mixer.STRUC_SIZE 6;
.linefile 16 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cmpd100.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stereo_3d_enhancement.h" 1
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/mute_control.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/mute_control.h"
.CONST $MUTE_CONTROL_VERSION 0x010000;

.CONST $M.MUTE_CONTROL.OFFSET_INPUT_PTR 0;
.CONST $M.MUTE_CONTROL.OFFSET_PTR_STATE 1;
.CONST $M.MUTE_CONTROL.OFFSET_MUTE_VAL 2;
.CONST $M.MUTE_CONTROL.STRUC_SIZE 3;
.linefile 19 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stereo_copy.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stereo_copy.h"
.CONST $M.audio_proc.stereo_copy.INPUT_CH1_PTR_BUFFER_FIELD 0;
.CONST $M.audio_proc.stereo_copy.INPUT_CH2_PTR_BUFFER_FIELD 1;
.CONST $M.audio_proc.stereo_copy.OUTPUT_CH1_PTR_BUFFER_FIELD 2;
.CONST $M.audio_proc.stereo_copy.OUTPUT_CH2_PTR_BUFFER_FIELD 3;
.CONST $M.audio_proc.stereo_copy.STRUC_SIZE 4;
.linefile 20 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/bass_management.h" 1
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/bass_management.h"
    .const $bass_management.LEFT_INPUT_PTR 0;
    .const $bass_management.RIGHT_INPUT_PTR 1;
    .const $bass_management.LEFT_OUTPUT_PTR 2;
    .const $bass_management.RIGHT_OUTPUT_PTR 3;
    .const $bass_management.LFE_INPUT_PTR 4;
    .const $bass_management.SUB_OUTPUT_PTR 5;
    .const $bass_management.BASS_BUFFER_PTR 6;
    .const $bass_management.COEFS_PTR 7;
    .const $bass_management.DATA_MEM_PTR 8;
    .const $bass_management.BYPASS_WORD_PTR 9;
    .const $bass_management.BYPASS_BIT_MASK_FIELD 10;
    .const $bass_management.CODEC_RATE_PTR 11;
    .const $bass_management.STRUCT_SIZE 12;




    .const $bass_management.COEF_CONFIG 0;
    .const $bass_management.COEF_A1 1;
    .const $bass_management.COEF_A2 2;
    .const $bass_management.COEF_A3 3;
    .const $bass_management.COEF_A4 4;
    .const $bass_management.COEF_A5 5;
    .const $bass_management.COEF_FREQ_PARAM 6;
    .const $bass_management.COEF_FREQ 7;

    .const $bass_management.COEF_NUM_HF_STAGES 8;
    .const $bass_management.COEF_NUM_LF_STAGES 9;

    .const $bass_management.COEF_STRUCT_BASE_SIZE 10;

    .const $bass_management.COEF_CONFIG.ENABLE_HPF 0x000001;
    .const $bass_management.COEF_CONFIG.ENABLE_LPF 0x000002;
.linefile 21 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/latency_measure.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/latency_measure.h"
   .CONST $pcm_latency.BUFFERS_LIST_FIELD 0;
   .CONST $pcm_latency.SAMPLES_LIST_FIELD 1;
   .CONST $pcm_latency.STRUC_SIZE 2;


   .CONST $encoded_latency.PCM_LATENCY_STRUCT_FIELD 0;
   .CONST $encoded_latency.CODEC_PACKETS_INFO_CBUFFER_FIELD 1;
   .CONST $encoded_latency.CODEC_CBUFFER_FIELD 2;
   .CONST $encoded_latency.DECODED_CBUFFER_FIELD 3;
   .CONST $encoded_latency.DECODER_INV_SAMPLE_RATE_FIELD 4;
   .CONST $encoded_latency.CURRENT_WARP_RATE_FIELD 5;
   .CONST $encoded_latency.SEARCH_MIN_LEN_FIELD 6;
   .CONST $encoded_latency.LATENCY_MEASUREMENT_LAST_CODED_RD_ADDR_FIELD 7;
   .CONST $encoded_latency.LATENCY_MEASUREMENT_LAST_DECODED_WR_ADDR_FIELD 8;
   .CONST $encoded_latency.TOTAL_LATENCY_US_FIELD 9;
   .CONST $encoded_latency.HIST_LATENCY_US_FIELD 10;
   .CONST $encoded_latency.STRUC_SIZE 14;
.linefile 22 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/volume_and_limit.h" 1
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/volume_and_limit.h"
   .CONST $volume_and_limit.OFFSET_CONTROL_WORD_FIELD 0;
   .CONST $volume_and_limit.OFFSET_BYPASS_BIT_FIELD 1;
   .CONST $volume_and_limit.NROF_CHANNELS_FIELD 2;
   .CONST $volume_and_limit.SAMPLE_RATE_PTR_FIELD 3;
   .CONST $volume_and_limit.MASTER_VOLUME_FIELD 4;
   .CONST $volume_and_limit.LIMIT_THRESHOLD_FIELD 5;
   .CONST $volume_and_limit.LIMIT_THRESHOLD_LINEAR_FIELD 6;
   .CONST $volume_and_limit.LIMIT_RATIO_FIELD_FIELD 7;
   .CONST $volume_and_limit.LIMITER_GAIN_FIELD 8;
   .CONST $volume_and_limit.LIMITER_GAIN_LINEAR_FIELD 9;
   .CONST $volume_and_limit.STRUC_SIZE 10;

   .CONST $volume_and_limit.CHANNELS_STRUCTURES_OFFSET_FIELD $volume_and_limit.STRUC_SIZE;


   .CONST $volume_and_limit.channel.INPUT_PTR_FIELD 0;
   .CONST $volume_and_limit.channel.OUTPUT_PTR_FIELD 1;
   .CONST $volume_and_limit.channel.TRIM_VOLUME_FIELD 2;
   .CONST $volume_and_limit.channel.CURRENT_VOLUME_FIELD 3;
   .CONST $volume_and_limit.channel.LAST_VOLUME_APPLIED_FIELD 4;
   .CONST $volume_and_limit.channel.STRUC_SIZE 5;






  .CONST $volume_and_limit.MIN_POSITIVE_VOLUME 0x080000;
  .CONST $volume_and_limit.VOLUME_RAMP_OFFSET_CONST (0.0001/16.0);
.linefile 23 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_system_library.h" 2

.CONST $M.CVC.CONFIG.CODEC_CNTL_FUNC 0;
.CONST $M.CVC.CONFIG.CONFIG_FUNC 1;
.CONST $M.CVC.CONFIG.PERSIS_FUNC 2;
.CONST $M.CVC.CONFIG.SECURITY_ID 3;
.CONST $M.CVC.CONFIG.VERSION 4;
.CONST $M.CVC.CONFIG.STANDBY_MODE 5;
.CONST $M.CVC.CONFIG.HFK_MODE 6;
.CONST $M.CVC.CONFIG.NUM_MODES 7;
.CONST $M.CVC.CONFIG.CALLST_MUTE 8;
.CONST $M.CVC.CONFIG.NUM_PARAMS 9;
.CONST $M.CVC.CONFIG.PARAMS_PTR 10;
.CONST $M.CVC.CONFIG.DEF_PARAMS_PTR 11;
.CONST $M.CVC.CONFIG.SYS_ID 12;
.CONST $M.CVC.CONFIG.SYS_FS 13;
.CONST $M.CVC.CONFIG.CVC_BANDWIDTH_INIT_FUNC 14;
.CONST $M.CVC.CONFIG.STATUS_PTR 15;
.CONST $M.CVC.CONFIG.TONE_MIX_PTR 16;
.CONST $M.CVC.CONFIG.PTR_INV_DAC_TABLE 17;
.CONST $M.CVC.CONFIG.STRUC_SIZE 18;


.CONST $M.CVC.VMMSG.READY 0x1000;
.CONST $M.CVC.VMMSG.SETMODE 0x1001;
.CONST $M.CVC.VMMSG.VOLUME 0x1002;
.CONST $M.CVC.VMMSG.SETPARAM 0x1004;
.CONST $M.CVC.VMMSG.CODEC 0x1006;
.CONST $M.CVC.VMMSG.PING 0x1008;
.CONST $M.CVC.VMMSG.PINGRESP 0x1009;
.CONST $M.CVC.VMMSG.SECPASSED 0x100c;
.CONST $M.CVC.VMMSG.SETSCOTYPE 0x100d;
.CONST $M.CVC.VMMSG.GETPARAM 0x1010;
.CONST $M.CVC.VMMSG.GETPARAM_RESP 0x1011;
.CONST $M.CVC.VMMSG.LOADPARAMS 0x1012;
.CONST $M.CVC.VMMSG.SECFAILED 0x1013;
.CONST $M.CVC.VMMSG.LOADPERSIST 0x1014;
.CONST $M.CVC.VMMSG.LOADPERSIST_RESP 0x1015;
.CONST $M.CVC.VMMSG.STOREPERSIST 0x1016;


.CONST $M.CVC.SPIMSG.STATUS 0x1007;
.CONST $M.CVC.SPIMSG.PARAMS 0x1008;
.CONST $M.CVC.SPIMSG.REINIT 0x1009;
.CONST $M.CVC.SPIMSG.VERSION 0x100A;
.CONST $M.CVC.SPIMSG.CONTROL 0x100B;


.CONST $M.SSR.START 0x1020;
.CONST $M.SSR.SET_CONFIG_VALUES 0x1021;



.CONST $M.CVC_SYS.CONTROL.DAC_OVERRIDE 0x8000;
.CONST $M.CVC_SYS.CONTROL.CALLSTATE_OVERRIDE 0x4000;
.CONST $M.CVC_SYS.CONTROL.MODE_OVERRIDE 0x2000;


.CONST $M.CVC.BANDWIDTH.NB 0;
.CONST $M.CVC.BANDWIDTH.UKN 1;
.CONST $M.CVC.BANDWIDTH.FE 2;
.CONST $M.CVC.BANDWIDTH.WB 3;

.CONST $M.CVC.BANDWIDTH.NB_FS 8000;
.CONST $M.CVC.BANDWIDTH.WB_FS 16000;
.CONST $M.CVC.BANDWIDTH.FE_FS 0;
.linefile 39 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_buffer.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_buffer.h"
.CONST $framesync_ind.CBUFFER_PTR_FIELD 0;
.CONST $framesync_ind.FRAME_PTR_FIELD 1;
.CONST $framesync_ind.CUR_FRAME_SIZE_FIELD 2;

.CONST $framesync_ind.FRAME_SIZE_FIELD 3;
.CONST $framesync_ind.JITTER_FIELD 4;
.CONST $framesync_ind.DISTRIBUTE_FUNCPTR_FIELD 5;
.CONST $framesync_ind.UPDATE_FUNCPTR_FIELD 6;
.CONST $framesync_ind.COUNTER_FIELD 7;
.CONST $framesync_ind.AMOUNT_DATA_FIELD 8;
.CONST $framesync_ind.THRESHOLD_FIELD 9;
.CONST $framesync_ind.MIN_FIELD 10;
.CONST $framesync_ind.MAX_FIELD 11;
.CONST $framesync_ind.DROP_INSERT_FIELD 12;


.CONST $framesync_ind.SYNC_POINTER_FIELD 7;
.CONST $framesync_ind.SYNC_MULTIPLIER_FIELD 8;
.CONST $framesync_ind.SYNC_AMOUNT_DATA_FIELD 9;



.CONST $framesync_ind.ENTRY_SIZE_FIELD 13;
.linefile 40 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbuffer.h" 1
.linefile 41 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_tsksched.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_tsksched.h"
.CONST $FRM_SCHEDULER.COUNT_FIELD 0;
.CONST $FRM_SCHEDULER.MAX_COUNT_FIELD 1;
.CONST $FRM_SCHEDULER.NUM_TASKS_FIELD 2;
.CONST $FRM_SCHEDULER.TOTAL_MIPS_FIELD 3;
.CONST $FRM_SCHEDULER.SEND_MIPS_FIELD 4;
.CONST $FRM_SCHEDULER.TOTALTM_FIELD 5;
.CONST $FRM_SCHEDULER.TOTALSND_FIELD 6;
.CONST $FRM_SCHEDULER.TIMER_FIELD 7;
.CONST $FRM_SCHEDULER.TRIGGER_FIELD 8;
.CONST $FRM_SCHEDULER.TASKS_FIELD 9;
.linefile 42 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 1
.linefile 9 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stack.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/timer.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/message.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/message.h"
.linefile 1 "C:/ADK3.5/kalimba/architecture/architecture.h" 1
.linefile 20 "C:/ADK3.5/kalimba/architecture/architecture.h"
.linefile 1 "C:/ADK3.5/kalimba/architecture/gordon.h" 1
.linefile 9 "C:/ADK3.5/kalimba/architecture/gordon.h"
   .CONST $FLASHWIN1_START 0xFFB000;
   .CONST $FLASHWIN1_SIZE 0x001000;
   .CONST $FLASHWIN2_START 0xFFC000;
   .CONST $FLASHWIN2_SIZE 0x001000;
   .CONST $FLASHWIN3_START 0xFFD000;
   .CONST $FLASHWIN3_SIZE 0x001000;
   .CONST $MCUWIN1_START 0xFFE000;
   .CONST $MCUWIN1_SIZE 0x001000;
   .CONST $MCUWIN2_START 0xFFF000;
   .CONST $MCUWIN2_SIZE 0x000E00;

   .CONST $PMWIN_HI_START 0x020000;
   .CONST $PMWIN_LO_START 0x030000;
   .CONST $PMWIN_24_START 0x040000;
   .CONST $PMWIN_SIZE 0x003000;

   .CONST $FLASHWIN1_LARGE_START 0xD00000;
   .CONST $FLASHWIN1_LARGE_SIZE 0x100000;
   .CONST $FLASHWIN2_LARGE_START 0xE00000;
   .CONST $FLASHWIN2_LARGE_SIZE 0x100000;
   .CONST $FLASHWIN3_LARGE_START 0xF00000;
   .CONST $FLASHWIN3_LARGE_SIZE 0x0D0000;





   .CONST $INT_LOAD_INFO_CLR_REQ_MASK 16384;

   .CONST $INT_SOURCE_TIMER1_POSN 0;
   .CONST $INT_SOURCE_TIMER2_POSN 1;
   .CONST $INT_SOURCE_MCU_POSN 2;
   .CONST $INT_SOURCE_PIO_POSN 3;
   .CONST $INT_SOURCE_MMU_UNMAPPED_POSN 4;
   .CONST $INT_SOURCE_SW0_POSN 5;
   .CONST $INT_SOURCE_SW1_POSN 6;
   .CONST $INT_SOURCE_SW2_POSN 7;
   .CONST $INT_SOURCE_SW3_POSN 8;

   .CONST $INT_SOURCE_TIMER1_MASK 1;
   .CONST $INT_SOURCE_TIMER2_MASK 2;
   .CONST $INT_SOURCE_MCU_MASK 4;
   .CONST $INT_SOURCE_PIO_MASK 8;
   .CONST $INT_SOURCE_MMU_UNMAPPED_MASK 16;
   .CONST $INT_SOURCE_SW0_MASK 32;
   .CONST $INT_SOURCE_SW1_MASK 64;
   .CONST $INT_SOURCE_SW2_MASK 128;
   .CONST $INT_SOURCE_SW3_MASK 256;

   .CONST $INT_SOURCE_TIMER1_EVENT 0;
   .CONST $INT_SOURCE_TIMER2_EVENT 1;
   .CONST $INT_SOURCE_MCU_EVENT 2;
   .CONST $INT_SOURCE_PIO_EVENT 3;
   .CONST $INT_SOURCE_MMU_UNMAPPED_EVENT 4;
   .CONST $INT_SOURCE_SW0_EVENT 5;
   .CONST $INT_SOURCE_SW1_EVENT 6;
   .CONST $INT_SOURCE_SW2_EVENT 7;
   .CONST $INT_SOURCE_SW3_EVENT 8;





   .CONST $CLK_DIV_1 0;
   .CONST $CLK_DIV_2 1;
   .CONST $CLK_DIV_4 3;
   .CONST $CLK_DIV_8 7;
   .CONST $CLK_DIV_16 15;
   .CONST $CLK_DIV_32 31;
   .CONST $CLK_DIV_64 63;
   .CONST $CLK_DIV_128 127;
   .CONST $CLK_DIV_256 255;
   .CONST $CLK_DIV_512 511;
   .CONST $CLK_DIV_1024 1023;
   .CONST $CLK_DIV_2048 2047;
   .CONST $CLK_DIV_4096 4095;
   .CONST $CLK_DIV_8192 8191;
   .CONST $CLK_DIV_16384 16383;


   .CONST $CLK_DIV_MAX $CLK_DIV_64;



   .CONST $N_FLAG 1;
   .CONST $Z_FLAG 2;
   .CONST $C_FLAG 4;
   .CONST $V_FLAG 8;
   .CONST $UD_FLAG 16;
   .CONST $SV_FLAG 32;
   .CONST $BR_FLAG 64;
   .CONST $UM_FLAG 128;

   .CONST $NOT_N_FLAG (65535-$N_FLAG);
   .CONST $NOT_Z_FLAG (65535-$Z_FLAG);
   .CONST $NOT_C_FLAG (65535-$C_FLAG);
   .CONST $NOT_V_FLAG (65535-$V_FLAG);
   .CONST $NOT_UD_FLAG (65535-$UD_FLAG);
   .CONST $NOT_SV_FLAG (65535-$SV_FLAG);
   .CONST $NOT_BR_FLAG (65535-$BR_FLAG);
   .CONST $NOT_UM_FLAG (65535-$UM_FLAG);
.linefile 21 "C:/ADK3.5/kalimba/architecture/architecture.h" 2
.linefile 1 "C:/ADK3.5/kalimba/architecture/gordon_io_defs.h" 1




   .CONST $FLASH_CACHE_SIZE_1K_ENUM 0x000000;
   .CONST $FLASH_CACHE_SIZE_512_ENUM 0x000001;
   .CONST $ADDSUB_SATURATE_ON_OVERFLOW_POSN 0x000000;
   .CONST $ADDSUB_SATURATE_ON_OVERFLOW_MASK 0x000001;
   .CONST $ARITHMETIC_16BIT_MODE_POSN 0x000001;
   .CONST $ARITHMETIC_16BIT_MODE_MASK 0x000002;
   .CONST $DISABLE_UNBIASED_ROUNDING_POSN 0x000002;
   .CONST $DISABLE_UNBIASED_ROUNDING_MASK 0x000004;
   .CONST $DISABLE_FRAC_MULT_ROUNDING_POSN 0x000003;
   .CONST $DISABLE_FRAC_MULT_ROUNDING_MASK 0x000008;
   .CONST $DISABLE_RMAC_STORE_ROUNDING_POSN 0x000004;
   .CONST $DISABLE_RMAC_STORE_ROUNDING_MASK 0x000010;
   .CONST $FLASHWIN_CONFIG_NOSIGNX_POSN 0x000000;
   .CONST $FLASHWIN_CONFIG_NOSIGNX_MASK 0x000001;
   .CONST $FLASHWIN_CONFIG_24BIT_POSN 0x000001;
   .CONST $FLASHWIN_CONFIG_24BIT_MASK 0x000002;
   .CONST $INT_EVENT_TIMER1_POSN 0x000000;
   .CONST $INT_EVENT_TIMER1_MASK 0x000001;
   .CONST $INT_EVENT_TIMER2_POSN 0x000001;
   .CONST $INT_EVENT_TIMER2_MASK 0x000002;
   .CONST $INT_EVENT_XAP_POSN 0x000002;
   .CONST $INT_EVENT_XAP_MASK 0x000004;
   .CONST $INT_EVENT_PIO_POSN 0x000003;
   .CONST $INT_EVENT_PIO_MASK 0x000008;
   .CONST $INT_EVENT_MMU_UNMAPPED_POSN 0x000004;
   .CONST $INT_EVENT_MMU_UNMAPPED_MASK 0x000010;
   .CONST $INT_EVENT_SW0_POSN 0x000005;
   .CONST $INT_EVENT_SW0_MASK 0x000020;
   .CONST $INT_EVENT_SW1_POSN 0x000006;
   .CONST $INT_EVENT_SW1_MASK 0x000040;
   .CONST $INT_EVENT_SW2_POSN 0x000007;
   .CONST $INT_EVENT_SW2_MASK 0x000080;
   .CONST $INT_EVENT_SW3_POSN 0x000008;
   .CONST $INT_EVENT_SW3_MASK 0x000100;
   .CONST $INT_EVENT_GPS_POSN 0x000009;
   .CONST $INT_EVENT_GPS_MASK 0x000200;
   .CONST $BITMODE_POSN 0x000000;
   .CONST $BITMODE_MASK 0x000003;
   .CONST $BITMODE_8BIT_ENUM 0x000000;
   .CONST $BITMODE_16BIT_ENUM 0x000001;
   .CONST $BITMODE_24BIT_ENUM 0x000002;
   .CONST $BYTESWAP_POSN 0x000002;
   .CONST $BYTESWAP_MASK 0x000004;
   .CONST $SATURATE_POSN 0x000003;
   .CONST $SATURATE_MASK 0x000008;
   .CONST $NOSIGNEXT_POSN 0x000003;
   .CONST $NOSIGNEXT_MASK 0x000008;
.linefile 22 "C:/ADK3.5/kalimba/architecture/architecture.h" 2
.linefile 1 "C:/ADK3.5/kalimba/architecture/gordon_io_map.h" 1




   .CONST $INT_SW_ERROR_EVENT_TRIGGER 0xFFFE00;
   .CONST $INT_GBL_ENABLE 0xFFFE11;
   .CONST $INT_ENABLE 0xFFFE12;
   .CONST $INT_CLK_SWITCH_EN 0xFFFE13;
   .CONST $INT_SOURCES_EN 0xFFFE14;
   .CONST $INT_PRIORITIES 0xFFFE15;
   .CONST $INT_LOAD_INFO 0xFFFE16;
   .CONST $INT_ACK 0xFFFE17;
   .CONST $INT_SOURCE 0xFFFE18;
   .CONST $INT_SAVE_INFO 0xFFFE19;
   .CONST $INT_ADDR 0xFFFE1A;
   .CONST $DSP2MCU_EVENT_DATA 0xFFFE1B;
   .CONST $PC_STATUS 0xFFFE1C;
   .CONST $MCU2DSP_EVENT_DATA 0xFFFE1D;
   .CONST $DOLOOP_CACHE_EN 0xFFFE1E;
   .CONST $TIMER1_EN 0xFFFE1F;
   .CONST $TIMER2_EN 0xFFFE20;
   .CONST $TIMER1_TRIGGER 0xFFFE21;
   .CONST $TIMER2_TRIGGER 0xFFFE22;
   .CONST $WRITE_PORT0_DATA 0xFFFE23;
   .CONST $WRITE_PORT1_DATA 0xFFFE24;
   .CONST $WRITE_PORT2_DATA 0xFFFE25;
   .CONST $WRITE_PORT3_DATA 0xFFFE26;
   .CONST $WRITE_PORT4_DATA 0xFFFE27;
   .CONST $WRITE_PORT5_DATA 0xFFFE28;
   .CONST $WRITE_PORT6_DATA 0xFFFE29;
   .CONST $WRITE_PORT7_DATA 0xFFFE2A;
   .CONST $READ_PORT0_DATA 0xFFFE2B;
   .CONST $READ_PORT1_DATA 0xFFFE2C;
   .CONST $READ_PORT2_DATA 0xFFFE2D;
   .CONST $READ_PORT3_DATA 0xFFFE2E;
   .CONST $READ_PORT4_DATA 0xFFFE2F;
   .CONST $READ_PORT5_DATA 0xFFFE30;
   .CONST $READ_PORT6_DATA 0xFFFE31;
   .CONST $READ_PORT7_DATA 0xFFFE32;
   .CONST $PORT_BUFFER_SET 0xFFFE33;
   .CONST $WRITE_PORT8_DATA 0xFFFE34;
   .CONST $WRITE_PORT9_DATA 0xFFFE35;
   .CONST $WRITE_PORT10_DATA 0xFFFE36;
   .CONST $READ_PORT8_DATA 0xFFFE38;
   .CONST $READ_PORT9_DATA 0xFFFE39;
   .CONST $READ_PORT10_DATA 0xFFFE3A;
   .CONST $MM_DOLOOP_START 0xFFFE40;
   .CONST $MM_DOLOOP_END 0xFFFE41;
   .CONST $MM_QUOTIENT 0xFFFE42;
   .CONST $MM_REM 0xFFFE43;
   .CONST $MM_RINTLINK 0xFFFE44;
   .CONST $CLOCK_DIVIDE_RATE 0xFFFE4D;
   .CONST $INT_CLOCK_DIVIDE_RATE 0xFFFE4E;
   .CONST $PIO_IN 0xFFFE4F;
   .CONST $PIO2_IN 0xFFFE50;
   .CONST $PIO_OUT 0xFFFE51;
   .CONST $PIO2_OUT 0xFFFE52;
   .CONST $PIO_DIR 0xFFFE53;
   .CONST $PIO2_DIR 0xFFFE54;
   .CONST $PIO_EVENT_EN_MASK 0xFFFE55;
   .CONST $PIO2_EVENT_EN_MASK 0xFFFE56;
   .CONST $INT_SW0_EVENT 0xFFFE57;
   .CONST $INT_SW1_EVENT 0xFFFE58;
   .CONST $INT_SW2_EVENT 0xFFFE59;
   .CONST $INT_SW3_EVENT 0xFFFE5A;
   .CONST $FLASH_WINDOW1_START_ADDR 0xFFFE5B;
   .CONST $FLASH_WINDOW2_START_ADDR 0xFFFE5C;
   .CONST $FLASH_WINDOW3_START_ADDR 0xFFFE5D;
   .CONST $NOSIGNX_MCUWIN1 0xFFFE5F;
   .CONST $NOSIGNX_MCUWIN2 0xFFFE60;
   .CONST $FLASHWIN1_CONFIG 0xFFFE61;
   .CONST $FLASHWIN2_CONFIG 0xFFFE62;
   .CONST $FLASHWIN3_CONFIG 0xFFFE63;
   .CONST $NOSIGNX_PMWIN 0xFFFE64;
   .CONST $PM_WIN_ENABLE 0xFFFE65;
   .CONST $STACK_START_ADDR 0xFFFE66;
   .CONST $STACK_END_ADDR 0xFFFE67;
   .CONST $STACK_POINTER 0xFFFE68;
   .CONST $STACK_OVERFLOW_PC 0xFFFE69;
   .CONST $FRAME_POINTER 0xFFFE6A;
   .CONST $NUM_RUN_CLKS_MS 0xFFFE6B;
   .CONST $NUM_RUN_CLKS_LS 0xFFFE6C;
   .CONST $NUM_INSTRS_MS 0xFFFE6D;
   .CONST $NUM_INSTRS_LS 0xFFFE6E;
   .CONST $NUM_STALLS_MS 0xFFFE6F;
   .CONST $NUM_STALLS_LS 0xFFFE70;
   .CONST $TIMER_TIME 0xFFFE71;
   .CONST $TIMER_TIME_MS 0xFFFE72;
   .CONST $WRITE_PORT0_CONFIG 0xFFFE73;
   .CONST $WRITE_PORT1_CONFIG 0xFFFE74;
   .CONST $WRITE_PORT2_CONFIG 0xFFFE75;
   .CONST $WRITE_PORT3_CONFIG 0xFFFE76;
   .CONST $WRITE_PORT4_CONFIG 0xFFFE77;
   .CONST $WRITE_PORT5_CONFIG 0xFFFE78;
   .CONST $WRITE_PORT6_CONFIG 0xFFFE79;
   .CONST $WRITE_PORT7_CONFIG 0xFFFE7A;
   .CONST $READ_PORT0_CONFIG 0xFFFE7B;
   .CONST $READ_PORT1_CONFIG 0xFFFE7C;
   .CONST $READ_PORT2_CONFIG 0xFFFE7D;
   .CONST $READ_PORT3_CONFIG 0xFFFE7E;
   .CONST $READ_PORT4_CONFIG 0xFFFE7F;
   .CONST $READ_PORT5_CONFIG 0xFFFE80;
   .CONST $READ_PORT6_CONFIG 0xFFFE81;
   .CONST $READ_PORT7_CONFIG 0xFFFE82;
   .CONST $PM_FLASHWIN_START_ADDR 0xFFFE83;
   .CONST $PM_FLASHWIN_SIZE 0xFFFE84;
   .CONST $BITREVERSE_VAL 0xFFFE89;
   .CONST $BITREVERSE_DATA 0xFFFE8A;
   .CONST $BITREVERSE_DATA16 0xFFFE8B;
   .CONST $BITREVERSE_ADDR 0xFFFE8C;
   .CONST $ARITHMETIC_MODE 0xFFFE93;
   .CONST $FORCE_FAST_MMU 0xFFFE94;
   .CONST $DBG_COUNTERS_EN 0xFFFE9F;
   .CONST $PM_FLASHWIN_CACHE_SIZE 0xFFFEE0;
   .CONST $WRITE_PORT8_CONFIG 0xFFFEE1;
   .CONST $WRITE_PORT9_CONFIG 0xFFFEE2;
   .CONST $WRITE_PORT10_CONFIG 0xFFFEE3;
   .CONST $READ_PORT8_CONFIG 0xFFFEE5;
   .CONST $READ_PORT9_CONFIG 0xFFFEE6;
   .CONST $READ_PORT10_CONFIG 0xFFFEE7;

   .CONST $READ_CONFIG_GAP $READ_PORT8_CONFIG - $READ_PORT7_CONFIG;
   .CONST $READ_DATA_GAP $READ_PORT8_DATA - $READ_PORT7_DATA;
   .CONST $WRITE_CONFIG_GAP $WRITE_PORT8_CONFIG - $WRITE_PORT7_CONFIG;
   .CONST $WRITE_DATA_GAP $WRITE_PORT8_DATA - $WRITE_PORT7_DATA;


   .CONST $INT_UNBLOCK $INT_ENABLE;
.linefile 23 "C:/ADK3.5/kalimba/architecture/architecture.h" 2
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/message.h" 2






   .CONST $message.MAX_LONG_MESSAGE_TX_PAYLOAD_SIZE 80;
   .CONST $message.MAX_LONG_MESSAGE_RX_PAYLOAD_SIZE 80;



   .CONST $message.MAX_LONG_MESSAGE_TX_SIZE ($message.MAX_LONG_MESSAGE_TX_PAYLOAD_SIZE + 2);
   .CONST $message.MAX_LONG_MESSAGE_RX_SIZE ($message.MAX_LONG_MESSAGE_RX_PAYLOAD_SIZE + 2);


   .CONST $message.QUEUE_SIZE_IN_MSGS (($message.MAX_LONG_MESSAGE_TX_SIZE+3)>>2)+1;


   .CONST $message.QUEUE_SIZE_IN_WORDS ($message.QUEUE_SIZE_IN_MSGS * (1+4));
   .CONST $message.LONG_MESSAGE_BUFFER_SIZE (((($message.MAX_LONG_MESSAGE_RX_SIZE+3)>>2)+1) * 4);



   .CONST $message.MAX_MESSAGE_HANDLERS 50;





   .CONST $message.REATTEMPT_SEND_PERIOD 1000;


   .CONST $message.TO_DSP_SHARED_WIN_SIZE 4;
   .CONST $message.TO_MCU_SHARED_WIN_SIZE 4;
   .CONST $message.ACK_FROM_MCU ($MCUWIN1_START + 0);
   .CONST $message.ACK_FROM_DSP ($MCUWIN1_START + 1);
   .CONST $message.DATA_TO_MCU ($MCUWIN1_START + 2);
   .CONST $message.DATA_TO_DSP ($MCUWIN1_START + 2 + $message.TO_DSP_SHARED_WIN_SIZE);


   .CONST $message.LAST_ENTRY -1;


   .CONST $message.LONG_MESSAGE_MODE_ID -2;


   .CONST $message.NEXT_ADDR_FIELD 0;
   .CONST $message.ID_FIELD 1;
   .CONST $message.HANDLER_ADDR_FIELD 2;
   .CONST $message.MASK_FIELD 3;
   .CONST $message.STRUC_SIZE 4;


   .CONST $message.QUEUE_WORDS_PER_MSG (1+4);
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/interrupt.h" 1
.linefile 27 "C:/ADK3.5/kalimba/lib_sets/sdk/include/interrupt.h"
   .CONST $INTERRUPT_STORE_STATE_SIZE 48;
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/pskey.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/pskey.h"
   .CONST $pskey.NEXT_ENTRY_FIELD 0;
   .CONST $pskey.KEY_NUM_FIELD 1;
   .CONST $pskey.HANDLER_ADDR_FIELD 2;
   .CONST $pskey.STRUC_SIZE 3;



   .CONST $pskey.MAX_HANDLERS 50;

   .CONST $pskey.LAST_ENTRY -1;
   .CONST $pskey.REATTEMPT_TIME_PERIOD 10000;

   .CONST $pskey.FAILED_READ_LENGTH -1;
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/flash.h" 1
.linefile 16 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/wall_clock.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/wall_clock.h"
   .CONST $wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_VALUE 625;
   .CONST $wall_clock.FIRMWARE_WALL_CLOCK_PERIOD_SHIFT -1;

   .CONST $wall_clock.UPDATE_TIMER_PERIOD 100000;





   .CONST $wall_clock.MAX_WALL_CLOCKS 7;

   .CONST $wall_clock.LAST_ENTRY -1;

   .CONST $wall_clock.NEXT_ADDR_FIELD 0;
   .CONST $wall_clock.BT_ADDR_TYPE_FIELD 1;
   .CONST $wall_clock.BT_ADDR_WORD0_FIELD 2;
   .CONST $wall_clock.BT_ADDR_WORD1_FIELD 3;
   .CONST $wall_clock.BT_ADDR_WORD2_FIELD 4;
   .CONST $wall_clock.ADJUSTMENT_VALUE_FIELD 5;
   .CONST $wall_clock.CALLBACK_FIELD 6;
   .CONST $wall_clock.TIMER_STRUC_FIELD 7;
   .CONST $wall_clock.STRUC_SIZE 8 + $timer.STRUC_SIZE;

   .CONST $wall_clock.BT_TICKS_IN_7500_US 24;
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/pio.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/pio.h"
   .CONST $pio.NEXT_ADDR_FIELD 0;
   .CONST $pio.PIO_BITMASK_FIELD 1;
   .CONST $pio.HANDLER_ADDR_FIELD 2;
   .CONST $pio.STRUC_SIZE 3;



   .CONST $pio.MAX_HANDLERS 20;

   .CONST $pio.LAST_ENTRY -1;
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/profiler.h" 1
.linefile 41 "C:/ADK3.5/kalimba/lib_sets/sdk/include/profiler.h"
   .CONST $profiler.MAX_PROFILER_HANDLERS 50;

   .CONST $profiler.LAST_ENTRY -1;





   .CONST $profiler.UNINITIALISED -2;

   .CONST $profiler.NEXT_ADDR_FIELD 0;
   .CONST $profiler.CPU_FRACTION_FIELD 1;
   .CONST $profiler.START_TIME_FIELD 2;
   .CONST $profiler.INT_START_TIME_FIELD 3;
   .CONST $profiler.TOTAL_TIME_FIELD 4;

      .CONST $profiler.RUN_CLKS_MS_START_FIELD 5;
      .CONST $profiler.RUN_CLKS_LS_START_FIELD 6;
      .CONST $profiler.RUN_CLKS_MS_TOTAL_FIELD 7;
      .CONST $profiler.RUN_CLKS_LS_TOTAL_FIELD 8;
      .CONST $profiler.RUN_CLKS_AVERAGE_FIELD 9;
      .CONST $profiler.RUN_CLKS_MS_MAX_FIELD 10;
      .CONST $profiler.RUN_CLKS_LS_MAX_FIELD 11;
      .CONST $profiler.INT_START_CLKS_MS_FIELD 12;
      .CONST $profiler.INT_START_CLKS_LS_FIELD 13;
      .CONST $profiler.INSTRS_MS_START_FIELD 14;
      .CONST $profiler.INSTRS_LS_START_FIELD 15;
      .CONST $profiler.INSTRS_MS_TOTAL_FIELD 16;
      .CONST $profiler.INSTRS_LS_TOTAL_FIELD 17;
      .CONST $profiler.INSTRS_AVERAGE_FIELD 18;
      .CONST $profiler.INSTRS_MS_MAX_FIELD 19;
      .CONST $profiler.INSTRS_LS_MAX_FIELD 20;
      .CONST $profiler.INT_START_INSTRS_MS_FIELD 21;
      .CONST $profiler.INT_START_INSTRS_LS_FIELD 22;
      .CONST $profiler.STALLS_MS_START_FIELD 23;
      .CONST $profiler.STALLS_LS_START_FIELD 24;
      .CONST $profiler.STALLS_MS_TOTAL_FIELD 25;
      .CONST $profiler.STALLS_LS_TOTAL_FIELD 26;
      .CONST $profiler.STALLS_AVERAGE_FIELD 27;
      .CONST $profiler.STALLS_MS_MAX_FIELD 28;
      .CONST $profiler.STALLS_LS_MAX_FIELD 29;
      .CONST $profiler.INT_START_STALLS_MS_FIELD 30;
      .CONST $profiler.INT_START_STALLS_LS_FIELD 31;
      .CONST $profiler.TEMP_COUNT_FIELD 32;
      .CONST $profiler.COUNT_FIELD 33;
      .CONST $profiler.STRUC_SIZE 34;
.linefile 19 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/fwrandom.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/fwrandom.h"
   .CONST $fwrandom.NEXT_ENTRY_FIELD 0;
   .CONST $fwrandom.NUM_REQ_FIELD 1;
   .CONST $fwrandom.NUM_RESP_FIELD 2;
   .CONST $fwrandom.RESP_BUF_FIELD 3;
   .CONST $fwrandom.HANDLER_ADDR_FIELD 4;
   .CONST $fwrandom.STRUC_SIZE 5;



   .CONST $fwrandom.MAX_HANDLERS 50;

   .CONST $fwrandom.LAST_ENTRY -1;
   .CONST $fwrandom.REATTEMPT_TIME_PERIOD 10000;
   .CONST $fwrandom.MAX_RAND_BITS 512;

   .CONST $fwrandom.FAILED_READ_LENGTH -1;
.linefile 20 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h" 2
.linefile 43 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/fft_twiddle.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/fft_twiddle.h"
.MODULE $M.fft_twiddle;
   .DATASEGMENT DM;






      .CONST $FFT_LOW_RAM_USED 0;
.linefile 3892 "C:/ADK3.5/kalimba/lib_sets/sdk/include/fft_twiddle.h"
         .VAR/DM_REAL_TWIDDLE $fft.twiddle_real[128] =
            +1.0000000000,
            +0.0000000000,
            +0.7071067812,
            -0.7071067812,
            +0.9238795325,
            -0.3826834324,
            +0.3826834324,
            -0.9238795325,
            +0.9807852804,
            -0.1950903220,
            +0.5555702330,
            -0.8314696123,
            +0.8314696123,
            -0.5555702330,
            +0.1950903220,
            -0.9807852804,
            +0.9951847267,
            -0.0980171403,
            +0.6343932842,
            -0.7730104534,
            +0.8819212643,
            -0.4713967368,
            +0.2902846773,
            -0.9569403357,
            +0.9569403357,
            -0.2902846773,
            +0.4713967368,
            -0.8819212643,
            +0.7730104534,
            -0.6343932842,
            +0.0980171403,
            -0.9951847267,
            +0.9987954562,
            -0.0490676743,
            +0.6715589548,
            -0.7409511254,
            +0.9039892931,
            -0.4275550934,
            +0.3368898534,
            -0.9415440652,
            +0.9700312532,
            -0.2429801799,
            +0.5141027442,
            -0.8577286100,
            +0.8032075315,
            -0.5956993045,
            +0.1467304745,
            -0.9891765100,
            +0.9891765100,
            -0.1467304745,
            +0.5956993045,
            -0.8032075315,
            +0.8577286100,
            -0.5141027442,
            +0.2429801799,
            -0.9700312532,
            +0.9415440652,
            -0.3368898534,
            +0.4275550934,
            -0.9039892931,
            +0.7409511254,
            -0.6715589548,
            +0.0490676743,
            -0.9987954562,
            +0.9996988187,
            -0.0245412285,
            +0.6895405447,
            -0.7242470830,
            +0.9142097557,
            -0.4052413140,
            +0.3598950365,
            -0.9329927988,
            +0.9757021300,
            -0.2191012402,
            +0.5349976199,
            -0.8448535652,
            +0.8175848132,
            -0.5758081914,
            +0.1709618888,
            -0.9852776424,
            +0.9924795346,
            -0.1224106752,
            +0.6152315906,
            -0.7883464276,
            +0.8700869911,
            -0.4928981922,
            +0.2667127575,
            -0.9637760658,
            +0.9495281806,
            -0.3136817404,
            +0.4496113297,
            -0.8932243012,
            +0.7572088465,
            -0.6531728430,
            +0.0735645636,
            -0.9972904567,
            +0.9972904567,
            -0.0735645636,
            +0.6531728430,
            -0.7572088465,
            +0.8932243012,
            -0.4496113297,
            +0.3136817404,
            -0.9495281806,
            +0.9637760658,
            -0.2667127575,
            +0.4928981922,
            -0.8700869911,
            +0.7883464276,
            -0.6152315906,
            +0.1224106752,
            -0.9924795346,
            +0.9852776424,
            -0.1709618888,
            +0.5758081914,
            -0.8175848132,
            +0.8448535652,
            -0.5349976199,
            +0.2191012402,
            -0.9757021300,
            +0.9329927988,
            -0.3598950365,
            +0.4052413140,
            -0.9142097557,
            +0.7242470830,
            -0.6895405447,
            +0.0245412285,
            -0.9996988187;

         .VAR/DM_IMAG_TWIDDLE $fft.twiddle_imag[128] =
            +0.0000000000,
            -1.0000000000,
            -0.7071067812,
            -0.7071067812,
            -0.3826834324,
            -0.9238795325,
            -0.9238795325,
            -0.3826834324,
            -0.1950903220,
            -0.9807852804,
            -0.8314696123,
            -0.5555702330,
            -0.5555702330,
            -0.8314696123,
            -0.9807852804,
            -0.1950903220,
            -0.0980171403,
            -0.9951847267,
            -0.7730104534,
            -0.6343932842,
            -0.4713967368,
            -0.8819212643,
            -0.9569403357,
            -0.2902846773,
            -0.2902846773,
            -0.9569403357,
            -0.8819212643,
            -0.4713967368,
            -0.6343932842,
            -0.7730104534,
            -0.9951847267,
            -0.0980171403,
            -0.0490676743,
            -0.9987954562,
            -0.7409511254,
            -0.6715589548,
            -0.4275550934,
            -0.9039892931,
            -0.9415440652,
            -0.3368898534,
            -0.2429801799,
            -0.9700312532,
            -0.8577286100,
            -0.5141027442,
            -0.5956993045,
            -0.8032075315,
            -0.9891765100,
            -0.1467304745,
            -0.1467304745,
            -0.9891765100,
            -0.8032075315,
            -0.5956993045,
            -0.5141027442,
            -0.8577286100,
            -0.9700312532,
            -0.2429801799,
            -0.3368898534,
            -0.9415440652,
            -0.9039892931,
            -0.4275550934,
            -0.6715589548,
            -0.7409511254,
            -0.9987954562,
            -0.0490676743,
            -0.0245412285,
            -0.9996988187,
            -0.7242470830,
            -0.6895405447,
            -0.4052413140,
            -0.9142097557,
            -0.9329927988,
            -0.3598950365,
            -0.2191012402,
            -0.9757021300,
            -0.8448535652,
            -0.5349976199,
            -0.5758081914,
            -0.8175848132,
            -0.9852776424,
            -0.1709618888,
            -0.1224106752,
            -0.9924795346,
            -0.7883464276,
            -0.6152315906,
            -0.4928981922,
            -0.8700869911,
            -0.9637760658,
            -0.2667127575,
            -0.3136817404,
            -0.9495281806,
            -0.8932243012,
            -0.4496113297,
            -0.6531728430,
            -0.7572088465,
            -0.9972904567,
            -0.0735645636,
            -0.0735645636,
            -0.9972904567,
            -0.7572088465,
            -0.6531728430,
            -0.4496113297,
            -0.8932243012,
            -0.9495281806,
            -0.3136817404,
            -0.2667127575,
            -0.9637760658,
            -0.8700869911,
            -0.4928981922,
            -0.6152315906,
            -0.7883464276,
            -0.9924795346,
            -0.1224106752,
            -0.1709618888,
            -0.9852776424,
            -0.8175848132,
            -0.5758081914,
            -0.5349976199,
            -0.8448535652,
            -0.9757021300,
            -0.2191012402,
            -0.3598950365,
            -0.9329927988,
            -0.9142097557,
            -0.4052413140,
            -0.6895405447,
            -0.7242470830,
            -0.9996988187,
            -0.0245412285;
.linefile 4490 "C:/ADK3.5/kalimba/lib_sets/sdk/include/fft_twiddle.h"
.ENDMODULE;
.linefile 44 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators\\iir_resamplev2\\iir_resamplev2_header.h" 1
.linefile 45 "send_proc.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 1
.linefile 46 "send_proc.asm" 2
.linefile 1 "mips_profile.h" 1
.linefile 11 "mips_profile.h"
.CONST $mips_profile.MIPS.STAT_OFFSET 0;
.CONST $mips_profile.MIPS.TMAIN_OFFSET 1;
.CONST $mips_profile.MIPS.SMAIN_OFFSET 2;
.CONST $mips_profile.MIPS.TINT_OFFSET 3;
.CONST $mips_profile.MIPS.SINT_OFFSET 4;
.CONST $mips_profile.MIPS.SMAIN_INT_OFFSET 5;
.CONST $mips_profile.MIPS.MAIN_CYCLES_OFFSET 6;
.CONST $mips_profile.MIPS.INT_CYCLES_OFFSET 7;
.CONST $mips_profile.MIPS.TOT_CYCLES_OFFSET 8;
.CONST $mips_profile.MIPS.TEVAL_OFFSET 9;
.CONST $mips_profile.MIPS.BLOCK_SIZE 10;
.linefile 47 "send_proc.asm" 2
.linefile 64 "send_proc.asm"
.CONST $SND_IN_LEFT_JITTER 500;
.CONST $SND_IN_RIGHT_JITTER 500;
.CONST $REF_IN_JITTER 100;
.CONST $SND_OUT_JITTER 1000;
.linefile 76 "send_proc.asm"
.MODULE $M.CVC_MODULES_STAMP;
   .DATASEGMENT DM;
   .BLOCK ModulesStamp;
      .VAR s1 = 0xfeeb;
      .VAR s2 = 0xfeeb;
      .VAR s3 = 0xfeeb;
      .VAR CompConfig = 1*0x020000 + 1*0x010000 + 1*0x008000 + 1*0x002000 + 1*0x001000 + 1*0x000800 + 1*0x000200 + 0*0x000100 + 0*0x080000 + 0*0x100000 + 1*0x200000 + 1*0x000080 + 1*0x000040 + 1*0x000020 + 1*0x000010 + 1*0x000008 + 1*0x000004 + 1*0x000002 + 1*0x000001;
      .VAR s4 = 0xfeeb;
      .VAR s5 = 0xfeeb;
      .VAR s6 = 0xfeeb;
   .ENDBLOCK;
.ENDMODULE;

.MODULE $M.CVC_VERSION_STAMP;
   .DATASEGMENT DM;
   .BLOCK VersionStamp;
   .VAR h1 = 0xfebeef;
   .VAR h2 = 0x01beef;
   .VAR h3 = 0xbeef;
   .VAR SysID = $A2DP_LOW_LATENCY_2MIC_SYSID;
   .VAR BuildVersion = $CVC_VERSION;
   .VAR h4 = 0xccbeef;
   .VAR h5 = 0xbeef;
   .VAR h6 = 0xbeef;
   .ENDBLOCK;
.ENDMODULE;


.MODULE $M.CVC.data;
   .DATASEGMENT DM;


   .VAR ZeroValue = 0;
   .VAR OneValue = 1.0;
   .VAR MinusOne = -1;


   .VAR kap_version_stamp = &$M.CVC_VERSION_STAMP.VersionStamp;
   .VAR kap_modules_stamp = &$M.CVC_MODULES_STAMP.ModulesStamp;


   .VAR/DMCONST16 DefaultParameters_wb[] =
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/a2dp_low_latency_2mic_defaults_FA2M.dat" 1







0x0003, 0xE000, 0x0000,
0x0000, 0x0140, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x4000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0100, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0401,
0x0000, 0x0140, 0x0000,
0x3B0B, 0x1B85, 0x2809,
0x4000, 0x003B, 0x0B1B,
0x8528, 0x0900, 0x0001,
0x0004, 0x0100, 0x0001,
0x4000, 0x003B, 0x6E6E,
0x84BC, 0xE040, 0x0000,
0x3B6E, 0x6E84, 0xBCE0,
0x0000, 0x0100, 0x0000,
0x0000, 0x0140, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x4000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0100, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0140, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x4000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0100, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0140, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x4000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0100, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0140, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x4000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0100, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0140, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x4000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0100, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0140, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0001,
0x4000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0100, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0006,
0x0000, 0x0000, 0x000F,
0x0000, 0x0F00, 0x0010,
0x0003, 0x0609, 0x0C0F,
0x1215, 0x181B, 0x1E21,
0x2427, 0x2A2D, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0306,
0x090C, 0x0F12, 0x1518,
0x1B1E, 0x2124, 0x272A,
0x2D00, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x1000, 0x0306,
0x090C, 0x0F12, 0x1518,
0x1B1E, 0x2124, 0x272A,
0x2D00, 0x0000, 0x0000,
0x0000, 0x0310, 0x0000,
0x2000, 0x0000, 0x0042,
0x0000, 0x4220, 0x0000,
0x0000, 0x5000, 0x026A,
0x7FFF, 0xFFF9, 0xB037,
0xFA05, 0x42FE, 0x56CC,
0xFF80, 0x7110, 0x0000,
0x0800, 0x0001, 0x5555,
0x00CC, 0xCC42, 0x0B8B,
0x030F, 0x1042, 0x0B8B,
0x00EC, 0xE962, 0x032E,
0x009E, 0x217C, 0x997B,
0x0076, 0xAB08, 0x0000,
0xF9B0, 0x37FA, 0x0542,
0xFE56, 0xCCFF, 0x8071,
0x1000, 0x0008, 0x0000,
0x0155, 0x5500, 0xCCCC,
0x3E48, 0x5902, 0xD025,
0x3E48, 0x5900, 0xD9BA,
0x5E42, 0x7200, 0x914F,
0x7B6F, 0x0800, 0x6D0B,
0x0800, 0x0000, 0x0A5D,
0x0002, 0x5800, 0x0000,
0x0003, 0xE000, 0x03E0,
0x0003, 0xE000, 0x03E0,
0x0003, 0xE000, 0x03E0,
0x0003, 0xE000, 0x03E0,
0x0003, 0xE000, 0x03E0,
0x202A, 0x0F00, 0x00CF,
0x0000, 0xCF00, 0x0000,
0x0000, 0x0140, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x58E9, 0xFA3B, 0x6CD4,
0x2C90, 0x031D, 0xC87A,
0x1655, 0x8D0E, 0xED4A,
0x0B31, 0x9007, 0x7B2E,
0x059C, 0x2F03, 0xF8BD,
0x02CF, 0xCC01, 0xFD94,
0x0168, 0xC100, 0xFF65,
0x00B4, 0xCE00, 0x8000,
0x7FFF, 0xFF00, 0x8000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x2000, 0x0000, 0x0003,
0x0000, 0x0140, 0x0000,
0x373C, 0xC891, 0x866F,
0x373C, 0xC82F, 0xAE26,
0x92BB, 0x0337, 0x3CC8,
0x9186, 0x6F37, 0x3CC8,
0x2FAE, 0x2692, 0xBB03,
0x373C, 0xC891, 0x866F,
0x373C, 0xC82F, 0xAE26,
0x92BB, 0x0300, 0x0001,
0x0000, 0x0100, 0x0001,
0x4000, 0x0000, 0x0001,
0x4000, 0x0000, 0x0001,
0x0200, 0x000C, 0xCCCC,
0x093F, 0xB304, 0xB60B,
0x007A, 0xA600, 0x7AA6,
0x0B3F, 0x305A, 0x9DF6,
0x4000, 0x0065, 0xAC8B,
0x1800, 0x0034, 0xCE07,
0xDA9D, 0xF800, 0xA1E8,
0x0000, 0x1400, 0x0002,
0x0051, 0xD100, 0x51D1,
0x1ABE, 0x6000, 0x001A,
0x4000, 0x0000, 0x8000,
0xFD40, 0x0000, 0x5000,
0x0000, 0x3C00, 0x0000,
0xE715, 0xE600, 0x0058,
0x0395, 0x817F, 0xFFFF,
0x09F7, 0x3E61, 0x47AE,
0x6147, 0xAE20, 0x0000,
0x5999, 0x9A01, 0xFE3F,
0x03FC, 0x7F79, 0x9999,
0x7999, 0x99FA, 0x0541,
0x0000, 0x0800, 0x0010,
0x0000, 0x8D10, 0x09B9,
0x0000, 0x0140, 0x0000,
0x7F9B, 0xCE00, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000, 0x0000,
0x0000, 0x0000
.linefile 119 "send_proc.asm" 2
   ;

   .VAR CurParams[2*ROUND(0.5*$M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.STRUCT_SIZE)];


   .VAR/DM1 ref_delay_buffer[($M.CVC.Num_Samples_Per_Frame * 2)];
   .VAR/DM2 fft_circ[($M.filter_bank.Parameters.FFT256_BUFFLEN * 2)];


   .VAR/DM1 in0oms_LpX_queue[$M.oms270.QUE_LENGTH];





   .BLOCK/DM1 FFT_DM1;
      .VAR X_real[$M.CVC.Num_FFT_Freq_Bins];
      .VAR D_l_real[$M.CVC.Num_FFT_Freq_Bins];
      .VAR D_r_real[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM2 FFT_DM2;
      .VAR X_imag[$M.CVC.Num_FFT_Freq_Bins];
      .VAR D_l_imag[$M.CVC.Num_FFT_Freq_Bins];
      .VAR D_r_imag[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM1 $scratch.s;
      .VAR $scratch.s0;
      .VAR $scratch.s1;
      .VAR $scratch.s2;
      .VAR $scratch.s3;
      .VAR $scratch.s4;
      .VAR $scratch.s5;
      .VAR $scratch.s6;
      .VAR $scratch.s7;
      .VAR $scratch.s8;
      .VAR $scratch.s9;
   .ENDBLOCK;

   .BLOCK/DM2 $scratch.t;
      .VAR $scratch.t0;
      .VAR $scratch.t1;
      .VAR $scratch.t2;
      .VAR $scratch.t3;
      .VAR $scratch.t4;
      .VAR $scratch.t5;
      .VAR $scratch.t6;
      .VAR $scratch.t7;
      .VAR $scratch.t8;
      .VAR $scratch.t9;
   .ENDBLOCK;

   .BLOCK/DM1 $M.dm1_scratch;
      .VAR W_ri[2 * $M.CVC.Num_FFT_Freq_Bins +1];
      .VAR Attenuation_not_used[$M.CVC.Num_FFT_Freq_Bins];
      .VAR L_adaptA[$M.CVC.Num_FFT_Freq_Bins];
      .VAR L_adaptR[$M.CVC.Num_FFT_Freq_Bins];
      .VAR scratch_extra_dm1[$asf100.SCRATCH_SIZE_DM1 - ( 5*$M.CVC.Num_FFT_Freq_Bins+1 )];
   .ENDBLOCK;



   .VAR AttenuationPersist[$M.CVC.Num_FFT_Freq_Bins];
   .BLOCK/DM2 $M.dm2_scratch;

         .VAR Exp_Mts_adapt[2*$M.CVC.Num_FFT_Freq_Bins + 1];
         .VAR scratch_extra_dm2[$asf100.SCRATCH_SIZE_DM2 - ( 2*$M.CVC.Num_FFT_Freq_Bins + 1 )];
   .ENDBLOCK;
.linefile 207 "send_proc.asm"
   .VAR fft_obj[$M.filter_bank.fft.STRUC_SIZE] =
      0,
      &$M.dm1_scratch,
      &$M.dm2_scratch,
      &fft_circ,
      BITREVERSE(&fft_circ),
      $filter_bank.config.fftsplit_table,
      0 ...;



   .VAR dcblock_parameters_wb[] =
        1,
        1,
        0.5,

        0.973965227469013/2,-1.947930454938026/2,0.973965227469013/2,
        0.948608379214097/2,-1.947252530661955/2,

        1;
.linefile 236 "send_proc.asm"
   .VAR vad_peq_output_cbuffer_struc[$cbuffer.STRUC_SIZE] = 0 ...;

   .VAR vad_peq_output[$frmbuffer.STRUC_SIZE] =
            &vad_peq_output_cbuffer_struc,
            &$M.dm1_scratch,
            0;

   .VAR vad_peq_parameters_wb[] =
        3,
        1,
        0.5,

      3597684, -7593996, 4029366, 3454473, -7592720,
      3621202, -7734660, 4194304, 3639878, -7733107,
      4126472, -8041639, 4194304, 4107363, -8020823,

      1,1,1;



   .CONST $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT 0;
   .CONST $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT 1;
   .CONST $M.SET_MODE_GAIN.ADC_MIXER_EXP 2;
   .CONST $M.SET_MODE_GAIN.SCO_GAIN_MANT 3;
   .CONST $M.SET_MODE_GAIN.SCO_GAIN_EXP 4;
   .CONST $M.SET_MODE_GAIN.STRUC_SIZE 5;

   .VAR ModeControl[$M.SET_MODE_GAIN.STRUC_SIZE];

   .VAR/DM2 adc_mixer[$M.audio_proc.stream_mixer.STRUC_SIZE] =
      &stream_map_left_adc,
      &stream_map_right_adc,
      0,
      &ModeControl + $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT,
      &ModeControl + $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT,
      &ModeControl + $M.SET_MODE_GAIN.ADC_MIXER_EXP;


   .VAR/DM rcv_vad_peq[($audio_proc.peq.STRUC_SIZE + 2*((3)+1) )] =
      &stream_map_refin,
      &vad_peq_output,
      3,
      &$M.CVC.data.vad_peq_parameters_wb,

      0 ...;


   .VAR/DM1 rcv_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &vad_peq_output,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC,
        0 ...;






.CONST $SND_HARMONICITY_HISTORY_EXTENSION $M.CVC.Num_Samples_Per_Frame;




 .VAR/DM2 bufd_l_inp[$M.CVC.Num_FFT_Window + $SND_HARMONICITY_HISTORY_EXTENSION];
 .VAR/DM2 bufd_r_inp[$M.CVC.Num_FFT_Window];
.linefile 322 "send_proc.asm"
  .VAR fba_dm[$M.filter_bank.Parameters.TWO_CHNL_BLOCK_SIZE] =
      $filter_bank.config.frame120_proto240_fft256,
      &stream_map_left_adc,
      &stream_map_right_adc,
      &bufd_l_inp + $SND_HARMONICITY_HISTORY_EXTENSION,
      &bufd_r_inp,
      0,
      0,
      &D_l_real,
      &D_l_imag,
      &D_r_real,
      &D_r_imag,
      0 ...;



   .VAR/DM2 bufd_aec_inp[$M.CVC.Num_FFT_Window];

   .VAR/DM1 AecAnalysisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      $filter_bank.config.frame120_proto240_fft256,
      &stream_map_refin,
      &bufd_aec_inp,
      0,
      &X_real,
      &X_imag,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_REF_DELAY,
      &ref_delay_buffer,
      &ref_delay_buffer,
      LENGTH(ref_delay_buffer);


   .VAR bufd_outp[($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame)];

   .VAR/DM2 SndSynthesisBank[$M.filter_bank.Parameters.ONE_CHNL_BLOCK_SIZE] =
      $filter_bank.config.frame120_proto240_fft256,
      &stream_map_sndout,
      &bufd_outp,
      &fba_dm + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
      &X_real,
      &X_imag,
      0 ...;

      .VAR D0[] = &D_l_real,
                  &D_l_imag,
                  &fba_dm + $M.filter_bank.Parameters.OFFSET_CH1_BEXP;

      .VAR D1[] = &D_r_real,
                  &D_r_imag,
                  &fba_dm + $M.filter_bank.Parameters.OFFSET_CH2_BEXP;

      .VAR dmss_obj[$dmss.STRUC_SIZE] =
               &D0,
               &D1,
               0 ...;


      .VAR mgdc100_obj[$mgdc100.STRUC_SIZE] =
               &D0,
               &D1,
               &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MGDC_MAXCOMP,
               &$cvc_fftbins,
               &in0oms_G,
               0,
               &$cvc.dmss_mode,
               &oms270in0_obj + $M.oms270.VOICED_FIELD,
               0 ...;



         .VAR/DM1 nc_scratch_dm1[$nc100.DM1_SCRATCH_SIZE];
         .VAR/DM2 nc_ctrl[$nc100.NUM_PROC];
         .VAR nc100_dm1[$nc100.DM1_DATA_SIZE];
         .VAR nc100_dm2[$nc100.DM2_DATA_SIZE];
         .VAR nc100_obj[$nc100.STRUCT_SIZE] =
               &D0,
               &D1,
               &nc100_dm1,
               &nc100_dm2,
               &nc_scratch_dm1,
               &nc_ctrl,
               &$cvc.user.nc100_prep,
               &$cvc.user.nc100_pp,
               0,
               0 ...;




   .VAR in0oms_G[$M.CVC.Num_FFT_Freq_Bins];
   .VAR in0oms_LpXnz[$M.CVC.Num_FFT_Freq_Bins];
   .VAR in0oms_state[$M.oms270.STATE_LENGTH];

   .VAR oms270in0_obj[$M.oms270.STRUC_SIZE] =
        &$M.oms270.mode.wide_band.object,
        0,
        0,
        1,
        0,
        0,
        $M.CVC.Num_FFT_Window,
        0,
        &D_l_real,
        &D_l_imag,
        &fba_dm + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
        &D_l_real,
        &D_l_imag,
        0xFF0000,
        &in0oms_LpX_queue,
        &in0oms_G,
        &in0oms_LpXnz,
        &in0oms_state,
        &$M.dm1_scratch,
        0.03921056084768,
        0xFF23A7,
        0xFED889,
        0.45,
        $M.oms270.NOISE_THRESHOLD,
        0.95,
        0,
        0 ...;



   .VAR/DM sndLpX_queue[$dms100.QUE_LENGTH];
   .VAR G_dmsZ[$M.CVC.Num_FFT_Freq_Bins];
   .VAR LpXnz_dms[$M.CVC.Num_FFT_Freq_Bins];
   .VAR spp[$dms100.DIM];
   .VAR dms_state[$dms100.STATE_LENGTH];

   .VAR dms100_obj[$dms100.STRUC_SIZE] =
         &$dms100.wide_band.mode,
         0,
         0,
         1,
         0,
         1,
         $M.CVC.Num_FFT_Window,
         &bufd_l_inp,
         &D_l_real,
         &D_l_imag,
         &fba_dm + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
         &D_l_real,
         &D_l_imag,
         0xFF0000,
         &sndLpX_queue,
         &G_dmsZ,
         &LpXnz_dms,
         &dms_state,
         &$M.dm1_scratch,
         0.036805582279178,
         0xFF13DE,
         0xFEEB01,
         0.45,
         $dms100.NOISE_THRESHOLD,
         0.95,
         0,
         &aec_dm1 + $M.AEC_500.OFFSET_E_REAL_PTR,
         &D0,
         &D1,
         &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMS_AGGR,
         &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_LPN_MIC,
         &$cvc.dmss_mode,
         &spp,
         0 ...;



   .BLOCK/DM1;


        .VAR RcvBuf_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];

        .VAR Ga_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
        .VAR L2PxR[4];

        .VAR Gr_imag[$M.AEC_500.RER_dim];

        .VAR SqGr[$M.AEC_500.RER_dim];
        .VAR BExp_Ga[$M.CVC.Num_FFT_Freq_Bins];
        .VAR LPwrX0[$M.CVC.Num_FFT_Freq_Bins];
        .VAR RatFE[$M.AEC_500.RER_dim];
        .VAR Cng_Nz_Shape_Tab[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM2;


        .VAR RcvBuf_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];

        .VAR Ga_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
        .VAR L2absGr[$M.AEC_500.RER_dim];

        .VAR Gr_real[$M.AEC_500.RER_dim];
        .VAR LPwrD[$M.AEC_500.RER_dim];
        .VAR BExp_X_buf[$M.AEC_500.Num_Primary_Taps+1];
        .VAR LpZ_nz[$M.CVC.Num_FFT_Freq_Bins];
        .VAR LPwrX1[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM1;


        .VAR GaMic1_imag[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];

        .VAR BExp_GaMic1[$M.CVC.Num_FFT_Freq_Bins];
   .ENDBLOCK;

   .BLOCK/DM2;


        .VAR GaMic1_real[$M.CVC.Num_FFT_Freq_Bins * $M.AEC_500.Num_Primary_Taps];
   .ENDBLOCK;

   .VAR/DM1 aec_dm1[$M.AEC_500.STRUCT_SIZE] =
      &X_real,
      &X_imag,
      &fba_dm + $M.filter_bank.Parameters.OFFSET_CH1_BEXP,
      &D_l_real,
      &D_l_imag,
      &Exp_Mts_adapt,
      $AEC_500.rer_headset,
      0,
      0,
      &Gr_imag,
      &Gr_real,
      &SqGr,
      &L2absGr,
      &LPwrD,
      &W_ri,
      &L_adaptR,
      0,
      &X_real,
      &X_imag,
      &AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_PTR_BEXP,
      &G_dmsZ,
      &in0oms_LpXnz,
      &in0oms_G,
      &G_dmsZ,
      0,
      0x200000,
      $M.AEC_500.CNG_G_ADJUST,
      0.5,
      0.5,
      0.5,
      0,
      0,
      0x028000,
      $M.AEC_500.Num_Auxillary_Taps,
      $M.AEC_500.Num_Primary_Taps,
      $M.CVC.Num_FFT_Freq_Bins,
      &$M.AEC_500_WB.LPwrX_margin.overflow_bits,
      &$M.AEC_500_WB.LPwrX_margin.scale_factor,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      $M.AEC_500.L_MUA_ON,
      $M.AEC_500.L_ALFA_A,

      $M.AEC_500.dbl_talk_control_headset.normal_op,
      $M.AEC_500.dbl_talk_control_headset.normal_op_else,
      0,
      $AEC_500.LPwrX_update_headset,
      0,

      &$AEC_500.Const,
      &RcvBuf_real,
      &RcvBuf_imag,
      &Ga_imag,
      &Ga_real,
      0,
      0,
      &L2PxR,
      &BExp_Ga,
      0,
      &LPwrX0,
      &RatFE,
      &BExp_X_buf,
      &LpZ_nz,
      &LPwrX1,

      &AttenuationPersist,
      &L_adaptA,
      0,
      -268,
      3,
      &$M.AEC_500.wb_constants.nzShapeTables,
      &Cng_Nz_Shape_Tab,
      0 ...;

   .VAR/DM1 aec2Mic_dm1[$M.TWOMIC_AEC.STRUCT_SIZE] =
      &X_real,
      &X_imag,
      &fba_dm + $M.filter_bank.Parameters.OFFSET_CH2_BEXP,
      &D_r_real,
      &D_r_imag,
      &Exp_Mts_adapt,
      &aec_dm1,
      0,
      &GaMic1_real,
      &GaMic1_imag,
      &BExp_GaMic1,
      &RcvBuf_real,
      &RcvBuf_imag;

   .VAR/DM1 vsm_fdnlp_dm1[$M.AEC_500_HF.STRUCT_SIZE] =
      0,
      0,
      $M.CVC.Num_FFT_Freq_Bins,
      0,
      &$M.CVC_SYS.CurCallState,
      0,
      0,
      &rcv_vad400 + $M.vad400.FLAG_FIELD,
      0,
      0,
      $AEC_500.ApplyHalfDuplex,
      0,
      0,
      0,
      0,
      &AttenuationPersist,
      0 ...;



   .VAR/DM2 in_l_dcblock_dm2[($audio_proc.peq.STRUC_SIZE + 2*((1)+1) )] =
      &stream_map_left_adc,
      &stream_map_left_adc,
      1,
      &$M.CVC.data.dcblock_parameters_wb,
      0 ...;


   .VAR/DM2 in_r_dcblock_dm2[($audio_proc.peq.STRUC_SIZE + 2*((1)+1) )] =
      &stream_map_right_adc,
      &stream_map_right_adc,
      1,
      &$M.CVC.data.dcblock_parameters_wb,
      0 ...;

   .VAR/DM1 mute_cntrl_dm1[$M.MUTE_CONTROL.STRUC_SIZE] =
      &stream_map_sndout,
      &$M.CVC_SYS.CurCallState,
      $M.A2DP_LOW_LATENCY_2MIC.CALLST.MUTE;



   .VAR/DM2 snd_peq_dm2[($audio_proc.peq.STRUC_SIZE + 2*(((5))+1) )] =
      &stream_map_sndout,
      &stream_map_sndout,
      (5),
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_PEQ_CONFIG,
      0 ...;



   .VAR/DM2 snd_vad_peq[($audio_proc.peq.STRUC_SIZE + 2*((3)+1) )] =
      &stream_map_sndout,
      &vad_peq_output,
      3,
      &$M.CVC.data.vad_peq_parameters_wb,
      0 ...;

   .VAR vad_default_param[] =
         0x0051D1, 0x0051D1, 0x1ABE60, 0x00001A,
         0x400000, 0x008000, 0xFD4000, 0x005000,
         0x00003C;

   .VAR/DM1 snd_vad400[$M.vad400.OBJECT_SIZE_FIELD] =
      &vad_peq_output,
      &vad_default_param,
      0 ...;

   .VAR vad_echo_hold[$M.CVC.vad_hold.STRUC_SIZE] =
      &$cvc.snd_agc_vad,
      &rcv_vad400 + $M.vad400.FLAG_FIELD,
      0,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME,
      0 ...;

   .VAR vad_noise_hold[$M.CVC.vad_hold.STRUC_SIZE] =
      &$cvc.snd_agc_vad,
      &$cvc.snd_agc_vad_reverse,
      0,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_NOISE_HOLD_TIME,
      0 ...;



   .VAR/DM1 out_gain_dm1[$M.audio_proc.stream_gain.STRUC_SIZE] =
      &stream_map_sndout,
      &stream_map_sndout,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SNDGAIN_MANTISSA,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SNDGAIN_EXPONENT;



   .VAR/DM snd_agc400_dm[$M.agc400.STRUC_SIZE] =
      0,
      0,
      0,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SND_AGC_G_INITIAL,
      &stream_map_sndout,
      &stream_map_sndout,
      &vad_noise_hold + $M.CVC.vad_hold.FLAG_FIELD,
      0x7FFFFF,
      0,
      0 ...;


   .VAR mic_in_l_pk_dtct[] =
      &stream_map_left_adc,
      0;

   .VAR mic_in_r_pk_dtct[] =
      &stream_map_right_adc,
      0;

   .VAR sco_out_pk_dtct[] =
      &stream_map_sndout,
      0;



.BLOCK/DM;
   .VAR pX0[$asf100.NUM_PROC * 2];
   .VAR pX1[$asf100.NUM_PROC * 2];
   .VAR pXcR[$asf100.NUM_PROC * 2];
   .VAR pXcI[$asf100.NUM_PROC * 2];
   .VAR coh[$asf100.NUM_PROC * 2];
   .VAR wnr_g[$asf100.NUM_PROC * 2];
.ENDBLOCK;

.BLOCK/DM1;
   .VAR cc0_real[$asf100.NUM_PROC];
   .VAR phi0_real[$asf100.NUM_PROC];
   .VAR fd_w0_real[$asf100.NUM_PROC];
   .VAR fd_w1_real[$asf100.NUM_PROC];
   .VAR fw_w1_real[$asf100.NUM_PROC];
   .VAR comp_t_real[$asf100.NUM_PROC];
   .VAR beam_tr0[$asf100.NUM_PROC];
   .VAR coh_real[$asf100.NUM_PROC];
   .VAR coh_cos[$asf100.NUM_PROC];
.ENDBLOCK;

.BLOCK/DM2;
   .VAR cc0_imag[$asf100.NUM_PROC];
   .VAR phi0_imag[$asf100.NUM_PROC];
   .VAR fd_w0_imag[$asf100.NUM_PROC];
   .VAR fd_w1_imag[$asf100.NUM_PROC];
   .VAR fw_w1_imag[$asf100.NUM_PROC];
   .VAR comp_t_imag[$asf100.NUM_PROC];
   .VAR beam_tr1[$asf100.NUM_PROC];
   .VAR coh_sin[$asf100.NUM_PROC];
.ENDBLOCK;

   .VAR/DM1 asf_object[$asf100.STRUC_SIZE] =
      &D0,
      &D1,
      &$asf100.mode.wide_band,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ASF_MIC_DISTANCE,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_LPN_MIC,
      $M.dm1_scratch,
      $M.dm2_scratch,
      $asf100.app_prep,
      $asf100.app_pp,
      &$asf100.bf.adaptive_2mic_beam_nearfield,
      $cvc.DMSS_ASF_BEAM_MODE,
      &pX0,
      &pX1,
      &pXcR,
      &pXcI,
      &coh,
      &wnr_g,
      &cc0_real,
      &cc0_imag,
      &phi0_real,
      &phi0_imag,
      &fd_w0_real,
      &fd_w0_imag,
      &fd_w1_real,
      &fd_w1_imag,
      &fw_w1_real,
      &fw_w1_imag,
      &comp_t_real,
      &comp_t_imag,
      &beam_tr0,
      &beam_tr1,
      &coh_cos,
      &coh_sin,
      &spp + $asf100.BIN_SKIPPED,
      0 ...;



    .VAR/DM1 $adf200_data_dm1[$adf200.DATA_SIZE_DM1];
    .VAR/DM2 $adf200_data_dm2[$adf200.DATA_SIZE_DM2];

   .VAR adf_IntRatio0[$adf200.ADF_num_proc];
   .VAR adf_IntRatio1[$adf200.ADF_num_proc];

   .VAR adf200_obj[$adf200.STRUCT_SIZE] =
         &D0,
         &D1,
         &$adf200_data_dm1,
         &$adf200_data_dm2,
         &$M.dm1_scratch,
         &$M.dm2_scratch,
         &adf_IntRatio0,
         &adf_IntRatio1,

         &nc_ctrl,



         &$cvc.user.adf200_prep,
         &$cvc.user.adf200_pp,
         0 ...;




   .VAR/DMCONST ParameterMap[] =


      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CNG_Q, &aec_dm1 + $M.AEC_500.OFFSET_CNG_Q_ADJUST,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CNG_SHAPE, &aec_dm1 + $M.AEC_500.OFFSET_CNG_NOISE_COLOR,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DTC_AGGR, &aec_dm1 + $M.AEC_500.OFFSET_DTC_AGRESSIVENESS,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ENABLE_AEC_REUSE, &aec_dm1 + $M.AEC_500.OFFSET_ENABLE_AEC_REUSE,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG, &aec_dm1 + $M.AEC_500.OFFSET_CONFIG,




      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HD_THRESH_GAIN, &vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_HD_THRESH_GAIN,




      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE,&$M.system_config.data.dithertype,



      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG, &$M.system_config.data.stereo_3d_obj + 9,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_REFLECTION_DELAY, &$M.system_config.data.stereo_3d_obj + 10,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_SE_MIX, &$M.system_config.data.stereo_3d_obj + 11,



      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_CONTROL_WORD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MAKEUP_GAIN1, &$M.system_config.data.cmpd100_obj_44kHz + $cmpd100.OFFSET_MAKEUP_GAIN,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_THRESHOLD,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_EXPAND_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LINEAR_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_COMPRESS_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_INV_LIMIT_RATIO,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_EXPAND_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LINEAR_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_COMPRESS_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_ATTACK_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_LIMIT_DECAY_TC,
      &CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_MAKEUP_GAIN2, &$M.system_config.data.cmpd100_obj_48kHz + $cmpd100.OFFSET_MAKEUP_GAIN,



      0;



   .VAR/DMCONST StatisticsPtrs[] =
      $M.A2DP_LOW_LATENCY_2MIC.STATUS.BLOCK_SIZE,
      &StatisticsClrPtrs,

      &$M.CVC_SYS.cur_mode,
      &$M.CVC_SYS.SysControl,
      &$M.ConfigureSystem.PeakMipsTxFunc,
      &$M.back_end.PeakMipsDecoder,
      &$M.system_config.data.pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
   &$M.system_config.data.pcmin_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.dac_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
   &$M.system_config.data.dac_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &ZeroValue,
      &$M.CVC_SYS.CurDAC,

      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_CONFIG,




      &$M.CVC_MODULES_STAMP.CompConfig,




      &MinusOne,


      &$M.set_plugin.codec_type,
      &ZeroValue,
      &ZeroValue,
      &ZeroValue,
      &ZeroValue,
      &ZeroValue,
      &ZeroValue,
      &ZeroValue,
      &ZeroValue,
      &ZeroValue,
      &ZeroValue,
      &$M.set_codec_rate.current_codec_sampling_rate,
      &$M.CVC_SYS.CurCallState,
      &$M.CVC_SYS.SecStatus,
      &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
   &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_out_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.Sleep.Mips,
      &ZeroValue,
      &$M.CVC_SYS.ConnectStatus,
      &$M.adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_CURRENT_SIDETONE_GAIN,
      &ZeroValue,
      &$M.adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_PEAK_ST,

      &snd_agc400_dm + $M.agc400.OFFSET_INPUT_LEVEL_FIELD,
      &snd_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD,




      &aec_dm1 + $M.AEC_500.OFFSET_AEC_COUPLING,





      &asf_object + $asf100.wnr.MEAN_PWR_FIELD,
      &asf_object + $asf100.wnr.MEAN_G_FIELD,
      &asf_object + $asf100.wnr.WIND_FIELD;







.VAR/DMCONST StatisticsClrPtrs[] =
      &mic_in_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &mic_in_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &sco_out_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.pcmin_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.pcmin_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.dac_l_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.system_config.data.dac_r_pk_dtct + $M.audio_proc.peak_monitor.PEAK_LEVEL,
      &$M.adc_in.sidetone_copy_op.param + $cbops.sidetone_filter_op.OFFSET_PEAK_ST,
      0;



   .VAR/DM ReInitializeTable[] =







      $filter_bank.two_channel.analysis.initialize, &fft_obj, &fba_dm,

      $filter_bank.one_channel.synthesis.initialize, &fft_obj, &SndSynthesisBank,


      $dms100.initialize, 0, &dms100_obj,



      $filter_bank.one_channel.analysis.initialize, &fft_obj, &AecAnalysisBank,
      $M.AEC_500.Initialize.func, &vsm_fdnlp_dm1, &aec_dm1,
      $M.AEC_500.InitializeAEC1.func, 0, &aec2Mic_dm1,



      $asf100.initialize, 0, &asf_object,



      $audio_proc.peq.initialize, &in_l_dcblock_dm2, 0,
      $audio_proc.peq.initialize, &in_r_dcblock_dm2, 0,



      $audio_proc.peq.initialize, &snd_peq_dm2, 0,



      $audio_proc.peq.initialize, &rcv_vad_peq, 0,
      $M.vad400.initialize.func, &rcv_vad400, 0,



      $oms270.initialize, 0, &oms270in0_obj,



      $audio_proc.peq.initialize, &snd_vad_peq, 0,
      $M.vad400.initialize.func, &snd_vad400, 0,



      $M.agc400.initialize.func, 0, &snd_agc400_dm,


      $dmss.initialize, 0, &dmss_obj,


      $mgdc100.initialize, 0, &mgdc100_obj,



      $adf200.initialize, 0, &adf200_obj,



    $stereo_3d_enhancement.initialize, 0, &$M.system_config.data.stereo_3d_obj,



    $receive_proc.peq.initialize, &$M.system_config.data.spkr_eq_left_dm2, &$M.system_config.data.spkr_eq_bank_select,
    $receive_proc.peq.initialize, &$M.system_config.data.spkr_eq_right_dm2, &$M.system_config.data.spkr_eq_bank_select,



    $receive_proc.peq.initialize, &$M.system_config.data.boost_eq_left_dm2, &$M.system_config.data.boost_eq_bank_select,
    $receive_proc.peq.initialize, &$M.system_config.data.boost_eq_right_dm2, &$M.system_config.data.boost_eq_bank_select,



    $receive_proc.peq.initialize, &$M.system_config.data.user_eq_left_dm2, &$M.system_config.data.user_eq_bank_select,
    $receive_proc.peq.initialize, &$M.system_config.data.user_eq_right_dm2, &$M.system_config.data.user_eq_bank_select,



    $receive_proc.cmpd100.initialize, &$M.system_config.data.cmpd100_obj_44kHz, &$M.system_config.data.cmpd100_obj_48kHz,



      $nc100.initialize, 0, &nc100_obj,


      $cbops.sidestone_filter_op.InitializeFilter, &$M.adc_in.sidetone_copy_op.param, 0,
      $cvc.mc.reset, 0, 0,

      0;


   .VAR ModeProcTableSnd[$M.A2DP_LOW_LATENCY_2MIC.SYSMODE.MAX_MODES] =
      &copy_proc_funcsSnd,
      &copy_proc_funcsSnd,
      &copy_proc_funcsSnd,
      &hfk_proc_funcsSnd,
      &hfk_proc_funcsSnd;


 .VAR/DM hfk_proc_funcsSnd[] =


      $frame_sync.distribute_streams_ind, &snd_process_streams,0,


      $audio_proc.peq.process, &rcv_vad_peq, 0,
      $M.vad400.process.func, &rcv_vad400, 0,
      $cvc.mc.echo_detect, 0, 0,



      $audio_proc.peq.process, &in_l_dcblock_dm2, 0,
      $audio_proc.peq.process, &in_r_dcblock_dm2, 0,


      $M.audio_proc.peak_monitor.Process.func, &mic_in_l_pk_dtct, 0,
      $M.audio_proc.peak_monitor.Process.func, &mic_in_r_pk_dtct, 0,





      $filter_bank.two_channel.analysis.process, &fft_obj, &fba_dm,



      $mgdc100.process, &$cvc.mc.mgdc100, &mgdc100_obj,



      $oms270.process, $cvc.mc.in0oms, &oms270in0_obj,



      $cvc.user.aec_ref.filter_bank_analysis, &fft_obj, &AecAnalysisBank,
      $cvc.user.aec500_dm.fnmls_process, &aec2Mic_dm1, 0,



      $dmss.input_power_monitor, 0, &dmss_obj,



      $asf100.process, &$cvc.mc.asf100, &asf_object,



      $cvc.channel.add_headroom, &D0, &$cvc_fftbins,
      $cvc.channel.add_headroom, &D1, &$cvc_fftbins,
      $adf200.process, &$cvc.mc.adf200, &adf200_obj,



      $dmss.output_power_monitor, 0, &dmss_obj,



      $nc100.process, &$cvc.mc.nc100, &nc100_obj,



      $dms100.process, $cvc.mc.dms100, &dms100_obj,
      $dms100.apply_gain, $cvc.mc.dms_out, &dms100_obj,



      $cvc.user.dmss_TR, 0, 0,



      $cvc.user.aec500_nlp_process, &vsm_fdnlp_dm1, &aec_dm1,
      $cvc.user.aec500_cng_process, &aec_dm1, 0,


      $M.CVC.Zero_DC_Nyquist.func, &X_real, &X_imag,
      $filter_bank.one_channel.synthesis.process, &fft_obj, &SndSynthesisBank,


      $audio_proc.peq.process, &snd_peq_dm2, 0,



      $cvc.user.snd_vad.peq_process, &snd_vad_peq, 0,
      $cvc.user.snd_vad.vad_process, &snd_vad400, 0,


      $M.audio_proc.stream_gain.Process.func, &out_gain_dm1, 0,


      $cvc.user.agc_snd.process, 0, &snd_agc400_dm,


      $M.MUTE_CONTROL.Process.func, &mute_cntrl_dm1, 0,

      $M.audio_proc.peak_monitor.Process.func, &sco_out_pk_dtct, 0,

      $frame_sync.update_streams_ind, &snd_process_streams,0,

      0;




   .VAR/DM copy_proc_funcsSnd[] =

      $frame_sync.distribute_streams_ind, &snd_process_streams, 0,

      $cvc_Set_PassThroughGains, &ModeControl, 0,

      $M.audio_proc.peak_monitor.Process.func, &mic_in_l_pk_dtct, 0,
      $M.audio_proc.peak_monitor.Process.func, &mic_in_r_pk_dtct, 0,
      $M.audio_proc.stream_mixer.Process.func, &adc_mixer, 0,
      $M.audio_proc.peak_monitor.Process.func, &sco_out_pk_dtct, 0,

      $frame_sync.update_streams_ind, &snd_process_streams, 0,
      0;




   .VAR stream_map_refin[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.dac_out.Reference.cbuffer_struc,
      0,
      0,
      $M.CVC.DAC_Num_Samples_Per_Frame,
      $REF_IN_JITTER,
      $frame_sync.distribute_sync_stream_ind,
      $frame_sync.update_sync_streams_ind,
      &stream_map_left_adc,
      2,
      0 ...;






   .VAR stream_map_left_adc[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.adc_in.audio_in_left_cbuffer_struc,
      0,
      0,
      $M.CVC.Num_Samples_Per_Frame,
      $SND_IN_LEFT_JITTER,
      $frame_sync.distribute_input_stream_ind,
      $frame_sync.update_input_streams_ind,
      0 ...;
.linefile 1267 "send_proc.asm"
   .VAR stream_map_right_adc[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.adc_in.audio_in_right_cbuffer_struc,
      0,
      0,
      $M.CVC.Num_Samples_Per_Frame,
      $SND_IN_RIGHT_JITTER,
      $frame_sync.distribute_input_stream_ind,
      $frame_sync.update_input_streams_ind,
      0 ...;
.linefile 1284 "send_proc.asm"
   .VAR stream_map_sndout[$framesync_ind.ENTRY_SIZE_FIELD] =
      &$M.a2dp_out.encoder_in_cbuffer_struc,
      0,
      0,
      $M.CVC.Num_Samples_Per_Frame,
      $SND_OUT_JITTER,
      $frame_sync.distribute_output_stream_ind,
      $frame_sync.update_output_streams_ind,
      0 ...;
.linefile 1308 "send_proc.asm"
.VAR/DMCONST snd_process_streams[] =
   &stream_map_left_adc,
   &stream_map_right_adc,
   &stream_map_refin,
   &stream_map_sndout,
   0;

.ENDMODULE;

.MODULE $M.CVC.Zero_DC_Nyquist;
   .CODESEGMENT CVC_ZERO_DC_NYQUIST_PM;
func:

   r0 = M[$cvc_fftbins];
   r0 = r0 - 1;
   M[r7] = Null;
   M[r8] = Null;
   M[r7 + r0] = Null;
   M[r8 + r0] = Null;
   rts;
.ENDMODULE;






.MODULE $M.2mic.LoadPersistResp;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

.VAR persistent_mgdc = 0;
.VAR persistent_agc = 0x20000;

.CONST $CVC_2MIC_PERSIST_MGDC_OFFSET 0;
.CONST $CVC_2MIC_PERSIST_AGC_OFFSET 1;
.CONST $CVC_2MIC_PERSIST_LOAD_MSG_SIZE 2;

func:


   Null = r2 - $CVC_2MIC_PERSIST_LOAD_MSG_SIZE;
   if NZ rts;
   r0 = M[r3 + $CVC_2MIC_PERSIST_MGDC_OFFSET];
   r0 = r0 ASHIFT 8;
   M[persistent_mgdc] = r0;


   M[$M.CVC_SYS.AlgReInit] = r2;
   rts;



.ENDMODULE;
.linefile 1371 "send_proc.asm"
.MODULE $M.pblock_send_handler;
   .CODESEGMENT PBLOCK_SEND_HANDLER_PM;
   .DATASEGMENT DM;

   .CONST $CVC_2MIC_PERSIST_STORE_MSG_SIZE 3;

   .CONST $TIMER_PERIOD_PBLOCK_SEND_MICROS 3000*1000;


   .VAR $pblock_send_timer_struc[$timer.STRUC_SIZE];

$pblock_send_handler:



   .VAR persist_data_2mic[3];
   push rLink;

   r0 = M[$M.CVC.data.mgdc100_obj + $mgdc100.L2FBPXD_FIELD];
   M[$M.2mic.LoadPersistResp.persistent_mgdc]=r0;

   r0 = M[$pblock_key];
   M[&persist_data_2mic] = r0;

   r0 = M[$M.2mic.LoadPersistResp.persistent_mgdc];
   r0 = r0 ASHIFT -8;
   M[&persist_data_2mic + 1] = r0;

   r0 = M[$M.2mic.LoadPersistResp.persistent_agc];
   r0 = r0 ASHIFT -8;
   M[&persist_data_2mic + 2] = r0;

   r3 = $M.CVC.VMMSG.STOREPERSIST;
   r4 = $CVC_2MIC_PERSIST_STORE_MSG_SIZE;
   r5 = &persist_data_2mic;
   call $message.send_long;


   r1 = &$pblock_send_timer_struc;
   r2 = $TIMER_PERIOD_PBLOCK_SEND_MICROS;
   r3 = &$pblock_send_handler;
   call $timer.schedule_event_in_period;

   jump $pop_rLink_and_rts;




.ENDMODULE;
.linefile 1447 "send_proc.asm"
.MODULE $M.set_mode_gains;
    .CODESEGMENT SET_MODE_GAIN_PM;

$cvc_Set_PassThroughGains:
   r1 = &$M.CVC.data.stream_map_sndout;

   M[&$M.CVC.data.adc_mixer + $M.audio_proc.stream_mixer.OFFSET_OUTPUT_PTR]=r1;

   r0 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA];
   r5 = r0;

   r4 = M[$M.CVC_SYS.cur_mode];
   Null = r4 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.PSTHRGH_LEFT;
   if Z r5 = Null;
   if Z jump passthroughgains;
   Null = r4 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.PSTHRGH_RIGHT;
   if Z r0 = Null;
   if Z jump passthroughgains;


   r5 = Null;
   r0 = Null;
   r1 = 1;
   jump setgains;
passthroughgains:

   r1 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT];
setgains:
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_MANT_LEFT] = r0;
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_MANT_RIGHT] = r5;
   M[r7 + $M.SET_MODE_GAIN.ADC_MIXER_EXP] = r1;
   rts;

.ENDMODULE;
.linefile 1496 "send_proc.asm"
.CONST $cvc.DMSS_AGGR 0.4;
.CONST $cvc.DMSS_GMAX 1.0;
.CONST $cvc.DMSS_GMIN (1.0 - $cvc.DMSS_AGGR);
.CONST $cvc.DMSS_NC_CTRL_BIAS 5.0/(1<<7);
.CONST $cvc.DMSS_NC_CTRL_TRANS 2.0/(1<<4);
.CONST $cvc.DMSS_ASF_BEAM_MODE 1;

.MODULE $M.cvc_headset_2mic.user_process;
   .CODESEGMENT CVC_USER_PROC_PM;
   .DATASEGMENT DM;


   $cvc.user.adf200_prep:



   Null = M[$cvc.bypass_bf];
   if NZ rts;
   Null = $cvc.DMSS_ASF_BEAM_MODE;
   if Z rts;

   jump $adf200.phase_synchronize;

   $cvc.user.adf200_pp:



   Null = $cvc.DMSS_ASF_BEAM_MODE;
   if Z rts;
   Null = $cvc.DMSS_GMIN;
   if Z rts;

   r5 = $cvc.DMSS_GMIN;
   r6 = $cvc.DMSS_GMAX;
   jump $adf200.gain_regulation;



   $cvc.user.nc100_prep:
   push rLink;


   call $cvc.mc.adf200;






   r1 = &$M.CVC.data.beam_tr0 - $asf100.BIN_SKIPPED + $nc100.BIN_SKIPPED;
   r2 = &$M.CVC.data.beam_tr1 - $asf100.BIN_SKIPPED + $nc100.BIN_SKIPPED;
   r3 = $cvc.DMSS_NC_CTRL_BIAS;
   r4 = $cvc.DMSS_NC_CTRL_TRANS;
   call $nc100.compara;

   jump $pop_rLink_and_rts;

   $cvc.user.nc100_pp:



   Null = $cvc.DMSS_GMIN;
   if Z rts;

   r5 = $cvc.DMSS_GMIN;
   r6 = $cvc.DMSS_GMAX;
   jump $nc100.gain_regulation;



   $cvc.user.dmss_TR:
   push rLink;


   call $cvc.mc.dmss_mode;
   Null = r0;
   if NZ jump $pop_rLink_and_rts;

      r2 = &$M.CVC.data.G_dmsZ;
      r4 = &$M.CVC.data.beam_tr0;
      r5 = &$M.CVC.data.beam_tr1;

      r6 = &$M.CVC.data.adf_IntRatio0;
      r7 = &$M.CVC.data.adf_IntRatio1;
      call $cvc.mc.adf200;
      r8 = r0;



      call $dmss.calc_TR;

      jump $pop_rLink_and_rts;



   $cvc.user.agc_snd.process:
   r5 = $cvc.mc.agc_snd;
   r6 = $M.agc400.process.func;
   jump $cvc.module_process;




   $cvc.user.aec_ref.filter_bank_analysis:
   r5 = $cvc.mc.aec500;
   r6 = $filter_bank.one_channel.analysis.process;
   jump $cvc.module_process;

   $cvc.user.aec500_dm.fnmls_process:
   r5 = $cvc.mc.aec500_dm;
   r6 = $M.2Mic_aec.func;
   jump $cvc.module_process;

   $cvc.user.aec500_nlp_process:
   r5 = $cvc.mc.aec500_nlp;
   r6 = $AEC_500.NonLinearProcess;
   jump $cvc.module_process;

   $cvc.user.aec500_cng_process:
   r5 = $cvc.mc.aec500_cng;
   r6 = $M.AEC_500.comfort_noise_generator.func;
   jump $cvc.module_process;




   $cvc.user.snd_vad.peq_process:
   r5 = $cvc.mc.snd_vad;
   r6 = $audio_proc.peq.process;
   jump $cvc.module_process;

   $cvc.user.snd_vad.vad_process:
   r5 = $cvc.mc.snd_vad;
   r6 = $M.vad400.process.func;
   jump $cvc.module_process;


.ENDMODULE;
.linefile 1651 "send_proc.asm"
.MODULE $M.cvc_headset_2mic.module_control.initialize;
   .CODESEGMENT CVC_MODULE_CONTROL_INIT_PM;
   .DATASEGMENT DM;


   .VAR $cvc.powerup_hold_count = 15;
   .VAR $cvc.powerup_flag = 1;
   .VAR $cvc.bypass_bf = 0;
   .VAR $cvc.bypass_dms = 0;


   .VAR $cvc.dmss_mode;
   .VAR $cvc.echo_flag;
   .VAR $cvc.snd_agc_vad;
   .VAR $cvc.snd_agc_vad_reverse;
   .VAR $cvc.asf_bypassed;




$cvc.mc.reset:



   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.DMSS_MODE;
   M[$cvc.dmss_mode] = r0;


   M[$cvc.echo_flag] = 0;
   M[$cvc.snd_agc_vad] = 0;
   M[$cvc.snd_agc_vad_reverse] = 0;
   M[$cvc.asf_bypassed] = 0;




   r1 = M[$M.2mic.LoadPersistResp.persistent_mgdc];
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   Null = r0 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_MGDCPERSIST;
   if NZ r1 = Null;
   M[$M.CVC.data.mgdc100_obj + $mgdc100.L2FBPXD_FIELD] = r1;



   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_SNDAGC;
   if Z jump next2;
   r1 = 0;
   M[$M.CVC.data.snd_agc400_dm + $M.agc400.OFFSET_G_REAL_FIELD] = r1;
next2:




   r2 = M[$cvc.bypass_bf];
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_BF_FIELD] = r2;

   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];

   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_WNR;
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_WNR_FIELD] = r0;
   if Z r2 = 0;

   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_SPP;
   M[$M.CVC.data.asf_object + $asf100.BYPASS_FLAG_COH_FIELD] = r0;
   if Z r2 = 0;

   M[$cvc.asf_bypassed] = r2;



   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_SPP;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_SPP_FIELD] = r0;
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_NFLOOR;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_NFLOOR_FIELD] = r0;
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_GSMOOTH;
   M[$M.CVC.data.dms100_obj + $dms100.BYPASS_GSMOOTH_FIELD] = r0;
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.GSCHEME;
   M[$M.CVC.data.dms100_obj + $dms100.GSCHEME_FIELD] = r0;


   rts;

.ENDMODULE;
.linefile 1755 "send_proc.asm"
.MODULE $M.cvc_headset_2mic.module_control;
   .CODESEGMENT CVC_MODULE_CONTROL_PM;
   .DATASEGMENT DM;




$cvc.mc.powerup_detect:

   r0 = M[$cvc.powerup_hold_count];
   if Z rts;

   r0 = r0 - 1;
   M[$cvc.powerup_hold_count] = r0;
   if NZ rts;

   M[$cvc.powerup_flag] = 0;
   rts;



$cvc.mc.echo_detect:

   r1 = M[&$M.CVC.data.rcv_vad400 + $M.vad400.FLAG_FIELD];
   r2 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r2 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.HDBYP;
   if NZ r1 = 0;



   M[$cvc.echo_flag] = r1;
   rts;



$cvc.mc.agc_snd:

   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r1 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.BYPASS_SNDAGC;
   if NZ rts;
.linefile 1804 "send_proc.asm"
   r1 = M[&$M.CVC.data.snd_vad400 + $M.vad400.FLAG_FIELD];






   Null = M[&$M.CVC.data.dms100_obj + $dms100.DMS_MODE_FIELD];
   if NZ jump no_update_snd_agc_vad;
   r1 = M[&$M.CVC.data.dms100_obj + $dms100.VAD_VOICED_FIELD];

   r7 = M[&$M.CVC.data.dmss_obj + $dmss.DIFF_LP_FIELD];
   r7 = r7 - 98304;
   if LE r1 = 0;

   r7 = M[&$M.CVC.data.dms100_obj + $M.oms270.PTR_G_FIELD];
   I0 = r7;
   I0 = I0 + 1;
   r0 = M[I0,1];
   r10 = 51;
   r7 = 0.0196078;
   rMAC = 0;
   do mean_loop;
      rMAC = rMAC + r0 * r7 , r0 = M[I0,1];
   mean_loop:
   Null = rMAC - 0.45;
   if LE r1 = 0;

no_update_snd_agc_vad:


   M[$cvc.snd_agc_vad] = r1;

   r0 = 1;
   r1 = r0 - r1;
   M[$cvc.snd_agc_vad_reverse] = r1;

   push rLink;

   r7 = &$M.CVC.data.vad_echo_hold;
   call $M.vad_hold.process.func;


   r7 = &$M.CVC.data.vad_noise_hold;
   call $M.vad_hold.process.func;


   r7 = &$M.CVC.data.vad_echo_hold;
   r1 = M[r7 + $M.CVC.vad_hold.FLAG_FIELD];
   r0 = r0 AND r1;
   r7 = &$M.CVC.data.vad_noise_hold;
   M[r7 + $M.CVC.vad_hold.FLAG_FIELD] = r0;
   r0 = 0;

   jump $pop_rLink_and_rts;




$cvc.mc.snd_vad:
   r0 = 0;


   r1 = 1;
   Null = M[&$M.CVC.data.dms100_obj + $dms100.DMS_MODE_FIELD];
   if Z r0 = r1;

   rts;




$cvc.mc.in0oms:
   push rLink;


   call $cvc.mc.aec500;
   Null = r0;
   if Z jump $pop_rLink_and_rts;


   call $cvc.mc.mgdc100;

   jump $pop_rLink_and_rts;




$cvc.mc.aec500_dm:

   r0 = M[$cvc.dmss_mode];
   M[&$M.CVC.data.aec2Mic_dm1 + $M.TWOMIC_AEC.OFFSET_PTR_BYPASS_AEC1] = r0;







$cvc.mc.aec500:
   r0 = 1;


   r1 = M[$M.CVC_SYS.cur_mode];
   Null = r1 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.LOWVOLUME;
   if Z rts;

   r1 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   Null = r1 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.AECENA;
   if Z rts;


   r0 = 0;
   rts;




$cvc.mc.aec500_nlp:

   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.CONFIG.HDBYP;
   if NZ rts;


   jump $cvc.mc.aec500;




$cvc.mc.aec500_cng:
.linefile 1944 "send_proc.asm"
   jump $cvc.mc.aec500;




$cvc.mc.mgdc100:





   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_MGDC;
   if NZ rts;
.linefile 1969 "send_proc.asm"
   r0 = 0;
   r1 = M[$cvc.echo_flag];
   r2 = M[&$M.CVC.data.asf_object + $asf100.wnr.WIND_FIELD];
   Null = r1 + r2;
   if NZ jump hs_mgdc_update_done;
      r0 = 1;
      r1 = M[$M.CVC.data.mgdc100_obj + $mgdc100.PTR_OMS_VAD_FIELD];
      r1 = M[r1];
      if Z r0 = r0 + 1;
   hs_mgdc_update_done:
   M[$M.CVC.data.mgdc100_obj + $mgdc100.MGDC_UPDATE_FIELD] = r0;


   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.DMSS_MODE;
   rts;




$cvc.mc.asf100:





   r0 = M[$cvc.asf_bypassed];
   if NZ rts;


   jump $cvc.mc.dmss_mode;




$cvc.mc.adf200:





   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_ADF;
   if NZ rts;


   r0 = M[$cvc.dmss_mode];
   if NZ rts;


   jump $cvc.mc.powerup_detect;




$cvc.mc.nc100:





   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_NC;
   if NZ rts;


   r0 = M[&$M.CVC.data.asf_object + $asf100.wnr.WIND_FIELD];
   if NZ rts;


   jump $cvc.mc.dmss_mode;




$cvc.mc.dms100:
   r0 = M[$cvc.bypass_dms];
   rts;

$cvc.mc.dms_out:
   r0 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_DMSS_CONFIG];
   r0 = r0 AND $M.A2DP_LOW_LATENCY_2MIC.DMSS_CONFIG.BYPASS_DMS;
   rts;




$cvc.mc.dmss_mode:


   r0 = M[$cvc.dmss_mode];
   rts;

.ENDMODULE;
.linefile 2094 "send_proc.asm"
.MODULE $M.App.Codec.Apply;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$App.Codec.Apply:
   push rLink;
.linefile 2108 "send_proc.asm"
   r0 = $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC;






   M[&$M.CVC_SYS.VolState] = r0;


   r4 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ADC_GAIN_LEFT];
   r5 = M[$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_ADC_GAIN_RIGHT];
   r7 = M[$M.CVC_SYS.cur_mode];
.linefile 2129 "send_proc.asm"
   r2 = $M.CVC.VMMSG.CODEC;
   call $message.send_short;
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2143 "send_proc.asm"
.MODULE $M.CVC_AppHandleConfig;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$CVC_AppHandleConfig:

   r1 = M[$M.CVC_MODULES_STAMP.CompConfig];
   r1 = r1 AND (~(0x080000));
   r0 = r4 LSHIFT ( round(log2(0x100000)) - 1);
   r0 = r0 AND 0x100000;
   r1 = r1 OR r0;
   r0 = r4 LSHIFT ( round(log2(0x080000)));
   r0 = r0 AND 0x080000;
   r1 = r1 OR r0;
   M[$M.CVC_MODULES_STAMP.CompConfig] = r1;
   rts;
.ENDMODULE;
.linefile 2168 "send_proc.asm"
.MODULE $M.CVC.app.config;
   .DATASEGMENT DM;
   .CONST $CVC_TWOMIC_HEADSET_SECID 0x651F;


   .VAR CVC_config_struct[$M.CVC.CONFIG.STRUC_SIZE] =
      &$App.Codec.Apply,
      &$CVC_AppHandleConfig,
      $M.2mic.LoadPersistResp.func,
      $CVC_TWOMIC_HEADSET_SECID,
      $CVC_VERSION,
      $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.STANDBY,
      $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC,
      $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.MAX_MODES,
      $M.A2DP_LOW_LATENCY_2MIC.CALLST.MUTE,
      $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.STRUCT_SIZE,
      &$M.CVC.data.CurParams,
      &$M.CVC.data.DefaultParameters_wb,
      $A2DP_LOW_LATENCY_2MIC_SYSID,
      $M.CVC.BANDWIDTH.WB_FS,
      0,
      &$M.CVC.data.StatisticsPtrs,
      &$M.dac_out.auxillary_mix_left_op.param,
      &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE;
.ENDMODULE;
.linefile 2209 "send_proc.asm"
.MODULE $M.ConfigureSystem;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR PeakMipsTxFunc = 0;

   .VAR TxFuncMips_data_block[$mips_profile.MIPS.BLOCK_SIZE] =
     0,
     0,
     0,
     0,
     0,
     0,
     0,
     0,
     0,
     0;

   .VAR $cvc_fftbins = $M.CVC.Num_FFT_Freq_Bins;
   .VAR $pblock_key = ($A2DP_LOW_LATENCY_2MIC_SYSID >> 8) | ($M.CVC.BANDWIDTH.WB_FS/2000);

 .VAR cvc_bandwidth_param_wb[] =
            $M.CVC.BANDWIDTH.WB_FS,
            120,
            129,
            240,
            0,
            &$M.oms270.mode.wide_band.object,
            &$M.AEC_500_WB.LPwrX_margin.overflow_bits,
            &$M.AEC_500_WB.LPwrX_margin.scale_factor,
            &$M.AEC_500.wb_constants.nzShapeTables,

            &$M.CVC.data.vad_peq_parameters_wb,




            &$M.CVC.data.dcblock_parameters_wb,



            $filter_bank.config.frame120_proto240_fft256,
            $filter_bank.config.frame120_proto240_fft256,
            $filter_bank.config.frame120_proto240_fft256,

            $M.CVC.BANDWIDTH.WB_FS/2000,

            &$asf100.mode.wide_band,




            &$dms100.wide_band.mode,



            0;

$SendProcStart:

   push rLink;

   r0 = $M.CVC.BANDWIDTH.WB_FS/2000;
   r3 = r0 OR ($A2DP_LOW_LATENCY_2MIC_SYSID >> 8);
   M[$pblock_key] = r3;
   r2 = $M.CVC.VMMSG.LOADPERSIST;
   call $message.send_short;


   r1 = &$pblock_send_timer_struc;
   r2 = $TIMER_PERIOD_PBLOCK_SEND_MICROS;
   r3 = &$pblock_send_handler;
   call $timer.schedule_event_in;

   call $ConfigureSystem;

   r8 = &$M.CVC.app.config.CVC_config_struct;
   call $CVC.PowerUpReset;
   call $CVC.Start;

   jump $pop_rLink_and_rts;

$ConfigureSystem:
   push rLink;


   r6 = &cvc_bandwidth_param_wb;


   r1 = M[r6 + $CVC.BW.PARAM.Num_Samples_Per_Frame];




   r2 = M[$M.CVC.data.fba_dm + $M.filter_bank.Parameters.OFFSET_CH1_PTR_HISTORY];

   r2 = r2 - r1;
   M[$M.CVC.data.dms100_obj + $M.oms270.PTR_INP_X_FIELD] = r2;


   r0 = M[r6 + $CVC.BW.PARAM.Num_FFT_Freq_Bins];
   M[$cvc_fftbins] = r0;

   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_NUM_FREQ_BINS] = r0;
   M[&$M.CVC.data.vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_NUM_FREQ_BINS] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.Num_FFT_Window];

   M[&$M.CVC.data.dms100_obj + $M.oms270.FFT_WINDOW_SIZE_FIELD] = r0;


   M[&$M.CVC.data.oms270in0_obj + $M.oms270.FFT_WINDOW_SIZE_FIELD] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.OMS_MODE_OBJECT];

   M[&$M.CVC.data.oms270in0_obj + $M.oms270.PTR_MODE_FIELD] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.DMS_MODE];
   M[&$M.CVC.data.dms100_obj + $M.oms270.PTR_MODE_FIELD] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.AEC_LPWRX_MARGIN_OVFL];
   r1 = M[r6 + $CVC.BW.PARAM.AEC_LPWRX_MARGIN_SCL];
   r2 = M[r6 + $CVC.BW.PARAM.AEC_PTR_NZ_TABLES];
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_LPWRX_MARGIN_OVFL] = r0;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_LPWRX_MARGIN_SCL] = r1;
   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_PTR_NZ_TABLES] = r2;


   r0 = M[r6 + $CVC.BW.PARAM.VAD_PEQ_PARAM_PTR];

   M[&$M.CVC.data.rcv_vad_peq + $audio_proc.peq.PARAM_PTR_FIELD] = r0;


   M[&$M.CVC.data.snd_vad_peq + $audio_proc.peq.PARAM_PTR_FIELD] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.DCBLOC_PEQ_PARAM_PTR];
   M[&$M.CVC.data.in_l_dcblock_dm2 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
   M[&$M.CVC.data.in_r_dcblock_dm2 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.FB_CONFIG_AEC];
   M[&$M.CVC.data.AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;
   M[&$M.CVC.data.SndSynthesisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;




   M[&$M.CVC.data.fba_dm + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.ASF_MODE];
   M[&$M.CVC.data.asf_object + $asf100.MODE_FIELD] = r0;


   jump $pop_rLink_and_rts;

$SendProcRun:

   push rLink;

    r0 = &$M.adc_in.audio_in_left_cbuffer_struc;
    call $cbuffer.calc_amount_data;
    Null = r0 - $M.CVC.Num_Samples_Per_Frame;
    if NEG jump $pop_rLink_and_rts;

    Null = M[$M.CVC_SYS.AlgReInit];
    if NZ call $M.A2DP_LOW_LATENCY_2MIC.SystemReInitialize.func;


    r3 = M[$M.CVC_SYS.FrameCounter];
    r3 = r3 + 1;
    M[$M.CVC_SYS.FrameCounter] = r3;





      r1 = M[$M.CVC_SYS.SysMode];
      r2 = M[$M.CVC_SYS.VolState];
      Null = r1 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC;
      if Z r1 = r2;
      M[$M.CVC_SYS.cur_mode] = r1;

      r8 = &TxFuncMips_data_block;
      call $M.mips_profile.mainstart;


      r2 = &$M.CVC.data.ModeProcTableSnd;
      call $Security.ProcessFrame;

      r8 = &TxFuncMips_data_block;
      call $M.mips_profile.mainend;

      r0 = M[r8 + $mips_profile.MIPS.MAIN_CYCLES_OFFSET];
      M[&PeakMipsTxFunc] = r0;



   r7 = M[&$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_2MIC.PARAMETERS.OFFSET_HFK_CONFIG ];
   r8 = &$M.adc_in.sidetone_copy_op.param;
   r1 = M[$M.CVC_SYS.cur_mode];
   NULL = r1 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.FULLPROC;
   if Z jump jp_sidetone_enabled;
      NULL = r1 - $M.A2DP_LOW_LATENCY_2MIC.SYSMODE.LOWVOLUME;
      if NZ r7 = Null;
jp_sidetone_enabled:
   M[r8 + $cbops.sidetone_filter_op.OFFSET_ST_CONFIG_FIELD]=r7;
   call $cbops.sidetone_filter_op.SetMode;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2456 "send_proc.asm"
.MODULE $M.vad_hold.process;
   .CODESEGMENT PM;

func:
   r0 = M[r7 + $M.CVC.vad_hold.PTR_VAD_FLAG_FIELD];
   r0 = M[r0];
   r1 = M[r7 + $M.CVC.vad_hold.PTR_EVENT_FLAG_FIELD];
   r1 = M[r1];
   r2 = M[r7 + $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD];
   r3 = M[r7 + $M.CVC.vad_hold.PTR_HOLD_TIME_FRAMES_FIELD];
   r3 = M[r3];


   r2 = r2 - 1;
   if NEG r2 = 0;
   Null = r1;
   if NZ r2 = r3;
   M[r7 + $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD] = r2;
   if NZ r0 = Null;
   M[r7 + $M.CVC.vad_hold.FLAG_FIELD] = r0;
   rts;

.ENDMODULE;
