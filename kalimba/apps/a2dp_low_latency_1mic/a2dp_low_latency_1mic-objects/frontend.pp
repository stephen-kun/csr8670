.linefile 1 "frontend.asm"
.linefile 1 "<command-line>"
.linefile 1 "frontend.asm"
.linefile 29 "frontend.asm"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 1
.linefile 9 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stack.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
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
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 2
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
.linefile 30 "frontend.asm" 2
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
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/peq.h"
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
.linefile 31 "frontend.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 1
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h" 2
.linefile 32 "frontend.asm" 2
.linefile 1 "sr_adjustment_gaming.h" 1
.linefile 12 "sr_adjustment_gaming.h"
.CONST $sra.NO_ACTIVITY_PERIOD 30;



.CONST $sra.ACTIVITY_PERIOD_BEFORE_START 100;


.CONST $sra.IDLE_MODE 0;
.CONST $sra.COUNTING_MODE 1;


.CONST $sra.RATECALC_IDLE_MODE 0;
.CONST $sra.RATECALC_START_MODE 1;
.CONST $sra.RATECALC_ADD_MODE 2;

.CONST $sra.TRANSIENT_SAVING_MODE 0;
.CONST $sra.STEADY_SAVING_MODE 1;


.CONST $sra.BUFF_SIZE 32;


.CONST $sra.TAG_DURATION_FIELD 0;
.CONST $sra.CODEC_PORT_FIELD 1;
.CONST $sra.CODEC_CBUFFER_TO_TAG_FIELD 2;
.CONST $sra.AUDIO_CBUFFER_TO_TAG_FIELD 3;
.CONST $sra.MAX_RATE_FIELD 4;
.CONST $sra.AUDIO_AMOUNT_EXPECTED_FIELD 5;
.CONST $sra.TARGET_LEVEL_FIELD 6;
.CONST $sra.CODEC_DATA_READ_FIELD 7;
.CONST $sra.NO_CODEC_DATA_COUNTER_FIELD 8;
.CONST $sra.ACTIVE_PERIOD_COUNTER_FIELD 9;
.CONST $sra.MODE_FIELD 10;
.CONST $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD 11;
.CONST $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD 12;
.CONST $sra.TAG_TIME_COUNTER_FIELD 13;
.CONST $sra.RATECALC_MODE_FIELD 14;
.CONST $sra.CODEC_CBUFFER_PREV_READ_ADDR_FIELD 15;
.CONST $sra.AUDIO_CBUFFER_PREV_WRITE_ADDR_FIELD 16;
.CONST $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD 17;
.CONST $sra.SRA_RATE_FIELD 18;
.CONST $sra.RESET_HIST_FIELD 19;
.CONST $sra.HIST_INDEX_FIELD 20;
.CONST $sra.SAVIN_STATE_FIELD 21;
.CONST $sra.BUFFER_LEVEL_COUNTER_FIELD 22;
.CONST $sra.BUFFER_LEVEL_ACC_FIELD 23;
.CONST $sra.FIX_VALUE_FIELD 24;
.CONST $sra.RATE_BEFORE_FIX_FIELD 25;
.CONST $sra.LONG_TERM_RATE_FIELD 26;
.CONST $sra.LONG_TERM_RATE_DETECTED_FIELD 27;
.CONST $sra.AVERAGE_LEVEL_FIELD 28;
.CONST $sra.HIST_BUFF_FIELD 29;


.CONST $sra.STRUC_SIZE ($sra.HIST_BUFF_FIELD+$sra.BUFF_SIZE);
.linefile 33 "frontend.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/a2dp_low_latency_1mic_library_gen.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/a2dp_low_latency_1mic_library_gen.h"
.CONST $A2DP_LOW_LATENCY_1MIC_SYSID 0xE102;


.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.BASS_MANAGER_BYPASS 0x000800;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SPKR_EQ_BYPASS 0x000400;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.EQFLAT 0x000200;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.USER_EQ_BYPASS 0x000100;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.BASS_BOOST_BYPASS 0x000080;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SPATIAL_BYPASS 0x000040;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.COMPANDER_BYPASS 0x000020;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.DITHER_BYPASS 0x000010;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.USER_EQ_SELECT 0x000007;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.CNGENA 0x008000;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.RERENA 0x004000;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SND_AGCBYP 0x001000;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SNDOMSENA 0x000080;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SIDETONEENA 0x000010;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.WNRBYP 0x000008;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.AECENA 0x000002;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.HDBYP 0x000004;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONFIG.BYPASS_AGCPERSIST 0x040000;


.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CUR_MODE_OFFSET 0;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.SYSCONTROL_OFFSET 1;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.FUNC_MIPS_OFFSET 2;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.DECODER_MIPS_OFFSET 3;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_PCMINL_OFFSET 4;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_PCMINR_OFFSET 5;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_DACL_OFFSET 6;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_DACR_OFFSET 7;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_SUB_OFFSET 8;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CUR_DACL_OFFSET 9;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.USER_EQ_BANK_OFFSET 10;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CONFIG_FLAG_OFFSET 11;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.DELAY 12;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_TYPE_OFFSET 13;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_FS_OFFSET 14;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_CHANNEL_MODE 15;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_STAT1 16;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_STAT2 17;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_STAT3 18;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_STAT4 19;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_STAT5 20;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.INTERFACE_TYPE 21;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.INPUT_RATE 22;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.OUTPUT_RATE 23;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CODEC_RATE 24;

.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CALL_STATE_OFFSET 25;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.SEC_STAT_OFFSET 26;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_ADC_OFFSET 27;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_SCO_OUT_OFFSET 28;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_MIPS_OFFSET 29;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_AUX_OFFSET 30;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.SIDETONE_GAIN 31;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.VOLUME 32;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.CONNSTAT 33;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.PEAK_SIDETONE 34;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.SND_AGC_SPEECH_LVL 35;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.SND_AGC_GAIN 36;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.AEC_COUPLING_OFFSET 37;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.WNR_PWR_LVL 38;
.CONST $M.A2DP_LOW_LATENCY_1MIC.STATUS.BLOCK_SIZE 39;


.CONST $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.STANDBY 0;
.CONST $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.PASSTHRU 1;
.CONST $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.FULLPROC 2;
.CONST $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.LOWVOLUME 3;
.CONST $M.A2DP_LOW_LATENCY_1MIC.SYSMODE.MAX_MODES 4;


.CONST $M.A2DP_LOW_LATENCY_1MIC.CONTROL.DAC_OVERRIDE 0x8000;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONTROL.CALLSTATE_OVERRIDE 0x4000;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CONTROL.MODE_OVERRIDE 0x2000;


.CONST $M.A2DP_LOW_LATENCY_1MIC.INTERFACE.ANALOG 0;
.CONST $M.A2DP_LOW_LATENCY_1MIC.INTERFACE.I2S 1;


.CONST $M.A2DP_LOW_LATENCY_1MIC.CALLST.MUTE 0;
.CONST $M.A2DP_LOW_LATENCY_1MIC.CALLST.CONNECTED 1;


.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CONFIG 0;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_CONFIG 1;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_GAIN_EXP 2;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_GAIN_MANT 3;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B2 4;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B1 5;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B0 6;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_A2 7;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_A1 8;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B2 9;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B1 10;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B0 11;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_A2 12;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_A1 13;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B2 14;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B1 15;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B0 16;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_A2 17;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_A1 18;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B2 19;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B1 20;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B0 21;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_A2 22;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_A1 23;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B2 24;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B1 25;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B0 26;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_A2 27;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_A1 28;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE1 29;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE2 30;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE3 31;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE4 32;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ1_SCALE5 33;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_CONFIG 34;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_GAIN_EXP 35;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_GAIN_MANT 36;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B2 37;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B1 38;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B0 39;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_A2 40;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_A1 41;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B2 42;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B1 43;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B0 44;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_A2 45;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_A1 46;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B2 47;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B1 48;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B0 49;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_A2 50;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_A1 51;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B2 52;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B1 53;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B0 54;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_A2 55;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_A1 56;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B2 57;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B1 58;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B0 59;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_A2 60;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_A1 61;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE1 62;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE2 63;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE3 64;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE4 65;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SPKR_EQ2_SCALE5 66;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_CONFIG 67;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_GAIN_EXP 68;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_GAIN_MANT 69;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_B2 70;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_B1 71;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_B0 72;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_A2 73;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_A1 74;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ1_SCALE 75;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_CONFIG 76;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_GAIN_EXP 77;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_GAIN_MANT 78;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_B2 79;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_B1 80;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_B0 81;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_A2 82;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_A1 83;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BOOST_EQ2_SCALE 84;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_CONFIG 85;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_GAIN_EXP 86;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_GAIN_MANT 87;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_B2 88;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_B1 89;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_B0 90;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_A2 91;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE1_A1 92;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_B2 93;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_B1 94;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_B0 95;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_A2 96;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE2_A1 97;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_B2 98;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_B1 99;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_B0 100;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_A2 101;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE3_A1 102;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_B2 103;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_B1 104;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_B0 105;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_A2 106;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE4_A1 107;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_B2 108;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_B1 109;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_B0 110;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_A2 111;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_STAGE5_A1 112;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE1 113;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE2 114;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE3 115;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE4 116;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ1_SCALE5 117;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_CONFIG 118;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_GAIN_EXP 119;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_GAIN_MANT 120;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_B2 121;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_B1 122;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_B0 123;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_A2 124;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE1_A1 125;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_B2 126;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_B1 127;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_B0 128;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_A2 129;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE2_A1 130;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_B2 131;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_B1 132;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_B0 133;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_A2 134;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE3_A1 135;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_B2 136;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_B1 137;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_B0 138;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_A2 139;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE4_A1 140;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_B2 141;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_B1 142;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_B0 143;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_A2 144;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_STAGE5_A1 145;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE1 146;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE2 147;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE3 148;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE4 149;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ2_SCALE5 150;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_CONFIG 151;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_GAIN_EXP 152;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_GAIN_MANT 153;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_B2 154;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_B1 155;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_B0 156;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_A2 157;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE1_A1 158;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_B2 159;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_B1 160;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_B0 161;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_A2 162;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE2_A1 163;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_B2 164;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_B1 165;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_B0 166;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_A2 167;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE3_A1 168;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_B2 169;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_B1 170;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_B0 171;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_A2 172;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE4_A1 173;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_B2 174;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_B1 175;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_B0 176;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_A2 177;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_STAGE5_A1 178;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE1 179;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE2 180;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE3 181;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE4 182;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ3_SCALE5 183;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_CONFIG 184;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_GAIN_EXP 185;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_GAIN_MANT 186;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_B2 187;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_B1 188;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_B0 189;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_A2 190;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE1_A1 191;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_B2 192;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_B1 193;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_B0 194;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_A2 195;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE2_A1 196;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_B2 197;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_B1 198;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_B0 199;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_A2 200;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE3_A1 201;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_B2 202;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_B1 203;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_B0 204;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_A2 205;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE4_A1 206;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_B2 207;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_B1 208;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_B0 209;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_A2 210;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_STAGE5_A1 211;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE1 212;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE2 213;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE3 214;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE4 215;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ4_SCALE5 216;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_CONFIG 217;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_GAIN_EXP 218;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_GAIN_MANT 219;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_B2 220;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_B1 221;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_B0 222;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_A2 223;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE1_A1 224;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_B2 225;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_B1 226;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_B0 227;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_A2 228;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE2_A1 229;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_B2 230;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_B1 231;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_B0 232;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_A2 233;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE3_A1 234;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_B2 235;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_B1 236;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_B0 237;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_A2 238;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE4_A1 239;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_B2 240;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_B1 241;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_B0 242;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_A2 243;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_STAGE5_A1 244;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE1 245;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE2 246;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE3 247;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE4 248;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ5_SCALE5 249;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_CONFIG 250;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_GAIN_EXP 251;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_GAIN_MANT 252;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_B2 253;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_B1 254;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_B0 255;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_A2 256;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE1_A1 257;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_B2 258;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_B1 259;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_B0 260;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_A2 261;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE2_A1 262;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_B2 263;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_B1 264;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_B0 265;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_A2 266;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE3_A1 267;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_B2 268;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_B1 269;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_B0 270;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_A2 271;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE4_A1 272;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_B2 273;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_B1 274;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_B0 275;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_A2 276;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_STAGE5_A1 277;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE1 278;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE2 279;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE3 280;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE4 281;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ6_SCALE5 282;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_CONFIG 283;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_GAIN_EXP 284;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_GAIN_MANT 285;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_B2 286;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_B1 287;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_B0 288;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_A2 289;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE1_A1 290;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_B2 291;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_B1 292;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_B0 293;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_A2 294;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE2_A1 295;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_B2 296;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_B1 297;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_B0 298;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_A2 299;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE3_A1 300;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_B2 301;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_B1 302;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_B0 303;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_A2 304;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE4_A1 305;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_B2 306;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_B1 307;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_B0 308;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_A2 309;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_STAGE5_A1 310;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE1 311;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE2 312;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE3 313;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE4 314;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ7_SCALE5 315;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_CONFIG 316;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_GAIN_EXP 317;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_GAIN_MANT 318;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_B2 319;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_B1 320;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_B0 321;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_A2 322;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE1_A1 323;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_B2 324;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_B1 325;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_B0 326;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_A2 327;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE2_A1 328;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_B2 329;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_B1 330;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_B0 331;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_A2 332;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE3_A1 333;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_B2 334;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_B1 335;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_B0 336;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_A2 337;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE4_A1 338;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_B2 339;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_B1 340;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_B0 341;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_A2 342;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_STAGE5_A1 343;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE1 344;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE2 345;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE3 346;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE4 347;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ8_SCALE5 348;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_CONFIG 349;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_GAIN_EXP 350;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_GAIN_MANT 351;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_B2 352;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_B1 353;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_B0 354;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_A2 355;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE1_A1 356;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_B2 357;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_B1 358;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_B0 359;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_A2 360;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE2_A1 361;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_B2 362;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_B1 363;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_B0 364;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_A2 365;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE3_A1 366;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_B2 367;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_B1 368;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_B0 369;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_A2 370;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE4_A1 371;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_B2 372;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_B1 373;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_B0 374;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_A2 375;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_STAGE5_A1 376;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE1 377;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE2 378;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE3 379;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE4 380;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ9_SCALE5 381;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_CONFIG 382;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_GAIN_EXP 383;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_GAIN_MANT 384;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_B2 385;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_B1 386;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_B0 387;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_A2 388;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE1_A1 389;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_B2 390;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_B1 391;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_B0 392;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_A2 393;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE2_A1 394;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_B2 395;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_B1 396;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_B0 397;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_A2 398;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE3_A1 399;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_B2 400;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_B1 401;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_B0 402;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_A2 403;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE4_A1 404;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_B2 405;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_B1 406;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_B0 407;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_A2 408;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_STAGE5_A1 409;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE1 410;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE2 411;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE3 412;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE4 413;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ10_SCALE5 414;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_CONFIG 415;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_GAIN_EXP 416;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_GAIN_MANT 417;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_B2 418;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_B1 419;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_B0 420;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_A2 421;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE1_A1 422;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_B2 423;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_B1 424;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_B0 425;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_A2 426;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE2_A1 427;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_B2 428;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_B1 429;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_B0 430;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_A2 431;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE3_A1 432;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_B2 433;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_B1 434;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_B0 435;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_A2 436;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE4_A1 437;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_B2 438;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_B1 439;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_B0 440;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_A2 441;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_STAGE5_A1 442;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE1 443;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE2 444;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE3 445;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE4 446;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ11_SCALE5 447;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_CONFIG 448;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_GAIN_EXP 449;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_GAIN_MANT 450;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_B2 451;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_B1 452;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_B0 453;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_A2 454;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE1_A1 455;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_B2 456;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_B1 457;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_B0 458;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_A2 459;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE2_A1 460;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_B2 461;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_B1 462;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_B0 463;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_A2 464;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE3_A1 465;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_B2 466;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_B1 467;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_B0 468;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_A2 469;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE4_A1 470;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_B2 471;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_B1 472;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_B0 473;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_A2 474;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_STAGE5_A1 475;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE1 476;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE2 477;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE3 478;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE4 479;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_USER_EQ12_SCALE5 480;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_MAX_USER_EQ_BANKS 481;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SDICONFIG 482;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DAC_GAIN_L 483;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DAC_GAIN_R 484;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TABLE_SIZE 485;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE0 486;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE1 487;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE2 488;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE3 489;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE4 490;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE5 491;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE6 492;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE7 493;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE8 494;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE9 495;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE10 496;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE11 497;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE12 498;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE13 499;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE14 500;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE15 501;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SB_TABLE16 502;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE0 503;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE1 504;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE2 505;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE3 506;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE4 507;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE5 508;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE6 509;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE7 510;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE8 511;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE9 512;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE10 513;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE11 514;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE12 515;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE13 516;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE14 517;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE15 518;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_SW_TABLE16 519;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE_SIZE 520;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE0 521;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE1 522;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE2 523;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE3 524;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE4 525;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE5 526;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SWAT_TRIM_TABLE6 527;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BASS_MANAGER_CONFIG 528;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A1 529;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A2 530;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A3 531;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A4 532;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A5 533;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_BASS_MANAGER_COEF_FREQ 534;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_REFLECTION_DELAY 535;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SE_MIX 536;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD1 537;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD1 538;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD1 539;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD1 540;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO1 541;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO1 542;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO1 543;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO1 544;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC1 545;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC1 546;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC1 547;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC1 548;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC1 549;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC1 550;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC1 551;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC1 552;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_MAKEUP_GAIN1 553;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_THRESHOLD2 554;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_THRESHOLD2 555;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_THRESHOLD2 556;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_THRESHOLD2 557;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_EXPAND_RATIO2 558;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_LINEAR_RATIO2 559;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_COMPRESS_RATIO2 560;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_LIMIT_RATIO2 561;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_ATTACK_TC2 562;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_EXPAND_DECAY_TC2 563;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_ATTACK_TC2 564;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LINEAR_DECAY_TC2 565;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC2 566;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_COMPRESS_DECAY_TC2 567;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_ATTACK_TC2 568;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LIMIT_DECAY_TC2 569;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_MAKEUP_GAIN2 570;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SIGNAL_DETECT_THRESH 571;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SIGNAL_DETECT_TIMEOUT 572;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE 573;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC1_CONFIG 574;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC2_CONFIG 575;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC3_CONFIG 576;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC4_CONFIG 577;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC5_CONFIG 578;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC6_CONFIG 579;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC7_CONFIG 580;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC8_CONFIG 581;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC9_CONFIG 582;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CODEC10_CONFIG 583;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_CONFIG 584;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HFK_OMS_AGGR 585;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ASR_OMS_AGGR 586;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_OMS_HARMONICITY 587;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_WNR_AGGR 588;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_WNR_POWER_THRES 589;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_WNR_HOLD 590;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CNG_Q 591;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_CNG_SHAPE 592;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DTC_AGGR 593;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ENABLE_AEC_REUSE 594;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ADCGAIN 595;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_CONFIG 596;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_GAIN_EXP 597;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_GAIN_MANT 598;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B2 599;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B1 600;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B0 601;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_A2 602;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE1_A1 603;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B2 604;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B1 605;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B0 606;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_A2 607;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE2_A1 608;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B2 609;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B1 610;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B0 611;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_A2 612;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE3_A1 613;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B2 614;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B1 615;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B0 616;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_A2 617;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE4_A1 618;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B2 619;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B1 620;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B0 621;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_A2 622;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_STAGE5_A1 623;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE1 624;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE2 625;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE3 626;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE4 627;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_PEQ_SCALE5 628;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_LVMODE_THRES 629;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE 630;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE1 631;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE2 632;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE3 633;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE4 634;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE5 635;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE6 636;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE7 637;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE8 638;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE9 639;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE10 640;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE11 641;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE12 642;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE13 643;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE14 644;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE15 645;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_CLIP_POINT 646;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_ADJUST_LIMIT 647;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_STF_SWITCH 648;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_STF_NOISE_LOW_THRES 649;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_STF_NOISE_HIGH_THRES 650;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_STF_GAIN_EXP 651;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_STF_GAIN_MANTISSA 652;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_CONFIG 653;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_GAIN_EXP 654;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_GAIN_MANT 655;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_B2 656;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_B1 657;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_B0 658;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_A2 659;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE1_A1 660;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_B2 661;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_B1 662;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_B0 663;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_A2 664;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE2_A1 665;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_B2 666;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_B1 667;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_B0 668;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_A2 669;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_STAGE3_A1 670;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_SCALE1 671;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_SCALE2 672;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_SCALE3 673;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SNDGAIN_MANTISSA 674;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SNDGAIN_EXPONENT 675;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA 676;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT 677;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_REF_DELAY 678;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ADCGAIN_SSR 679;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_ATTACK_TC 680;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_DECAY_TC 681;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_ENVELOPE_TC 682;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_INIT_FRAME_THRESH 683;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_RATIO 684;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_MIN_SIGNAL 685;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_MIN_MAX_ENVELOPE 686;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_DELTA_THRESHOLD 687;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_VAD_COUNT_THRESHOLD 688;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_G_INITIAL 689;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_TARGET 690;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_ATTACK_TC 691;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_DECAY_TC 692;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_A_90_PK 693;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_D_90_PK 694;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_G_MAX 695;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_START_COMP 696;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_COMP 697;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_INP_THRESH 698;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_SP_ATTACK 699;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_AD_THRESH1 700;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_AD_THRESH2 701;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_G_MIN 702;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME 703;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC 704;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_DECAY_TC 705;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_ENVELOPE_TC 706;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_INIT_FRAME_THRESH 707;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_RATIO 708;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_MIN_SIGNAL 709;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_MIN_MAX_ENVELOPE 710;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_DELTA_THRESHOLD 711;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_RCV_VAD_COUNT_THRESHOLD 712;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_HD_THRESH_GAIN 713;

.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_0 714;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_1 715;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_2 716;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_3 717;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_4 718;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_5 719;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_6 720;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_7 721;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_8 722;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_DSP_USER_9 723;
.CONST $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.STRUCT_SIZE 724;
.linefile 34 "frontend.asm" 2
.linefile 44 "frontend.asm"
.CONST $ADCDAC_PERIOD_USEC 0.00075;
.CONST $AUDIO_IN_PORT ($cbuffer.READ_PORT_MASK + 0);
.CONST $AUDIO_LEFT_OUT_PORT ($cbuffer.WRITE_PORT_MASK + 0);
.CONST $AUDIO_RIGHT_OUT_PORT ($cbuffer.WRITE_PORT_MASK + 1);
.CONST $TONE_IN_PORT (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_PCM_AUDIO) + 3);
.CONST $OUTPUT_AUDIO_CBUFFER_SIZE (160 + 8*(750 * 48000/1000000));


.MODULE $cbops.scratch;
    .DATASEGMENT DM;

   .VAR BufferTable[9*$cbops_multirate.BufferTable.ENTRY_SIZE];


    .VAR/DMCIRC mem1[120]; .VAR cbuffer_struc1[$cbuffer.STRUC_SIZE] = LENGTH(mem1), &mem1, &mem1;
    .VAR/DMCIRC mem2[120]; .VAR cbuffer_struc2[$cbuffer.STRUC_SIZE] = LENGTH(mem2), &mem2, &mem2;
    .VAR/DMCIRC mem3[300]; .VAR cbuffer_struc3[$cbuffer.STRUC_SIZE] = LENGTH(mem3), &mem3, &mem3;

.ENDMODULE;
.linefile 88 "frontend.asm"
.MODULE $M.set_dac_rate;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR local_play_back;
   .VAR audio_if_mode;
   .VAR max_clock_mismatch;
   .VAR long_term_mismatch;

func:


   r1 = r1 AND 0xffff;

   r1 = r1 * 10 (int);

   M[$M.dac_out.current_dac_sampling_rate] = r1;
   M[max_clock_mismatch] = r2;
   M[long_term_mismatch] = r3;

   r0 = r4 AND $LOCAL_PLAYBACK_MASK;
   M[local_play_back] = r0;
   r0 = r4 AND $AUDIO_IF_MASK;
   M[audio_if_mode] = r0;
.linefile 123 "frontend.asm"
   r0=1;
   M[$M.dac_out.dac_sr_flag] = r0;
   rts;

.ENDMODULE;
.linefile 136 "frontend.asm"
.MODULE $M.adc_in;
   .DATASEGMENT DM;

       .VAR/DMCIRC audio_in_left[320]; .VAR audio_in_left_cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(audio_in_left), &audio_in_left, &audio_in_left;
       .VAR/DMCIRC sidetone_mem[(4*48)]; .VAR sidetone_cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(sidetone_mem), &sidetone_mem, &sidetone_mem;

    .VAR copy_struc[] =
         $cbops.scratch.BufferTable,
         &left_shift_op,
         &sidetone_resample_op,
         1,
         $AUDIO_IN_PORT,
         2,
         &audio_in_left_cbuffer_struc,
         sidetone_cbuffer_struc,
         1,
         &$cbops.scratch.cbuffer_struc1;

     .BLOCK left_shift_op;
         .VAR left_shift_op.prev_op = $cbops.NO_MORE_OPERATORS;
         .VAR left_shift_op.next_op = &sidetone_copy_op;
         .VAR left_shift_op.func = &$cbops.shift;
         .VAR left_shift_op.param[$cbops.shift.STRUC_SIZE] =
                  0,
                  1,
                  8;
     .ENDBLOCK;

     .BLOCK sidetone_copy_op;
       .VAR sidetone_copy_op.prev_op = &left_shift_op;
       .VAR sidetone_copy_op.next_op = &sidetone_resample_op;
       .VAR sidetone_copy_op.func = &$cbops.sidetone_filter_op;
       .VAR sidetone_copy_op.param[($cbops.sidetone_filter_op.PEQ_START_FIELD + ($audio_proc.peq.STRUC_SIZE + 2*((3)+1) ))] =
          1,
          3,
            $M.A2DP_LOW_LATENCY_1MIC.CONFIG.SIDETONEENA,
            &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_CLIP_POINT,
            0,
            0.0,
        &$M.CVC.data.ZeroValue,
            0,
            &$M.dac_out.auxillary_mix_left_op.param+$cbops.aux_audio_mix_op.OFFSET_INV_DAC_GAIN,
            0,
            0,
            0,
            0,
            3,
            &$M.CVC.data.CurParams + $M.A2DP_LOW_LATENCY_1MIC.PARAMETERS.OFFSET_ST_PEQ_CONFIG,
            0 ...;
     .ENDBLOCK;

     .BLOCK sidetone_resample_op;
        .VAR sidetone_resample_op.prev_op = &sidetone_copy_op;
        .VAR sidetone_resample_op.next_op = $cbops.NO_MORE_OPERATORS;
        .VAR sidetone_resample_op.func = $cbops_iir_resamplev2;
        .VAR sidetone_resample_op.param[$iir_resamplev2.OBJECT_SIZE] =
            3,
            2,
            0,
            -8,
            8,
            &$cbops.scratch.mem2,
            LENGTH($cbops.scratch.mem2),
            0 ...;
     .ENDBLOCK;

.ENDMODULE;


.MODULE $M.tone_in;
    .DATASEGMENT DM;

    .VAR/DMCIRC left_mem[192]; .VAR left_cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(left_mem), &left_mem, &left_mem;
    .VAR/DMCIRC right_mem[192]; .VAR right_cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(right_mem), &right_mem, &right_mem;
    .VAR aux_input_stream_available;
   .VAR/DM1CIRC tone_hist_left[$cbops.fir_resample.HIST_LENGTH];
   .VAR/DM1CIRC tone_hist_right[$cbops.fir_resample.HIST_LENGTH];
   .VAR current_tone_sampling_rate = 8000;

   .VAR copy_struc[] =
      $cbops.scratch.BufferTable,
      deinterleave_mix_op,
      copy_op_right,
      1,
      $TONE_IN_PORT,
      2,
      &left_cbuffer_struc,
      &right_cbuffer_struc,
      2,
      &$cbops.scratch.cbuffer_struc1,
      &$cbops.scratch.cbuffer_struc2;

   .BLOCK deinterleave_mix_op;
      .VAR deinterleave_mix_op.mtu_next = $cbops.NO_MORE_OPERATORS;
      .VAR deinterleave_mix_op.main_next = shift_op_left;
      .VAR deinterleave_mix_op.func = $cbops.deinterleave_mix;
      .VAR deinterleave_mix_op.param[$cbops.deinterleave_mix.STRUC_SIZE] =
         0,
         3,
         4,
         0 ;
   .ENDBLOCK;

   .BLOCK shift_op_left;
      .VAR shift_op_left.prev_op = deinterleave_mix_op;
      .VAR shift_op_left.next_op = &copy_op_left;
      .VAR shift_op_left.func = $cbops.shift;
      .VAR shift_op_left.param[$cbops.shift.STRUC_SIZE] =
         3,
         3,
         8;
   .ENDBLOCK;

   .BLOCK copy_op_left;
      .VAR copy_op_left.prev_op = &shift_op_left;
      .VAR copy_op_left.next_op = copy_left_to_right;
      .VAR copy_op_left.func = $cbops.fir_resample;
      .VAR copy_op_left.param[$cbops.fir_resample.STRUC_SIZE] =
         3,
         1,
         $sra_coeffs,
         current_tone_sampling_rate,
         $M.dac_out.current_dac_sampling_rate,
         tone_hist_left,
         0 ...;
   .ENDBLOCK;

   .BLOCK copy_left_to_right;
      .VAR copy_left_to_right.prev_op = &copy_op_left;
      .VAR copy_left_to_right.next_op = &$cbops.NO_MORE_OPERATORS;
      .VAR copy_left_to_right.func = $cbops.copy_op;
      .VAR copy_left_to_right.param[$cbops.copy_op.STRUC_SIZE] =
         1,
         2;
   .ENDBLOCK;

   .BLOCK shift_op_right;
      .VAR shift_op_right.prev_op = &copy_op_left;
      .VAR shift_op_right.next_op = &copy_op_right;
      .VAR shift_op_right.func = $cbops.shift;
      .VAR shift_op_right.param[$cbops.shift.STRUC_SIZE] =
         4,
         4,
         8;
   .ENDBLOCK;

  .BLOCK copy_op_right;
      .VAR copy_op_right.prev_op = &shift_op_right;
      .VAR copy_op_right.next_op = $cbops.NO_MORE_OPERATORS;
      .VAR copy_op_right.func = $cbops.fir_resample;
      .VAR copy_op_right.param[$cbops.fir_resample.STRUC_SIZE] =
         4,
         2,
         $sra_coeffs,
         current_tone_sampling_rate,
         $M.dac_out.current_dac_sampling_rate,
         tone_hist_right,
         0 ...;
   .ENDBLOCK;

.ENDMODULE;
.linefile 306 "frontend.asm"
.MODULE $M.dac_out_resample;
    .DATASEGMENT DM;

    .VAR/DMCIRC dac_out_left[$OUTPUT_AUDIO_CBUFFER_SIZE]; .VAR left_cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(dac_out_left), &dac_out_left, &dac_out_left;
    .VAR/DMCIRC dac_out_right[$OUTPUT_AUDIO_CBUFFER_SIZE]; .VAR right_cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(dac_out_right), &dac_out_right, &dac_out_right;

   .VAR/DM1CIRC sr_hist_left[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];
   .VAR/DM1CIRC sr_hist_right[$cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE];

       .VAR copy_struc[] =
        $cbops.scratch.BufferTable,
        &sync_op,
        &sw_rate_right_op,
        2,
        &left_cbuffer_struc,
        &right_cbuffer_struc,
        2,
        &$M.dac_out.left_cbuffer_struc,
        &$M.dac_out.right_cbuffer_struc,
        2,
        &$cbops.scratch.cbuffer_struc1,
        &$cbops.scratch.cbuffer_struc2;

    .BLOCK sync_op;
      .VAR sync_op.prev_op = $cbops.NO_MORE_OPERATORS;
      .VAR sync_op.next_op = &left_op;
      .VAR sync_op.func = $cbops.stereo_sync_op;
      .VAR sync_op.param[$cbops.stereo_sync_op.STRUC_SIZE] =
           0,
           1;
    .ENDBLOCK;

    .BLOCK left_op;
      .VAR left_op.prev_op = &sync_op;
      .VAR left_op.next_op = &sw_rate_left_op;
      .VAR left_op.func = $cbops_iir_resamplev2;
      .VAR left_op.param[$iir_resamplev2.OBJECT_SIZE] =
           0,
           4,
           0,
           -8,
           8,
           &$cbops.scratch.mem3,
           LENGTH($cbops.scratch.mem3),
           0 ...;
    .ENDBLOCK;

    .BLOCK sw_rate_left_op;
      .VAR sw_rate_left_op.mtu_next = &left_op;
      .VAR sw_rate_left_op.main_next = &right_op;
      .VAR sw_rate_left_op.func = &$cbops.rate_adjustment_and_shift;
      .VAR sw_rate_left_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
           4,
           2,
           0,
           0,
           &$sra_coeffs,
           &sr_hist_left,
           &sr_hist_left,
           &$sra_struct + $sra.SRA_RATE_FIELD,
           0,
           0 ...;
    .ENDBLOCK;

    .BLOCK right_op;
      .VAR right_op.prev_op = &sw_rate_left_op;
      .VAR right_op.next_op = &sw_rate_right_op;
      .VAR right_op.func = $cbops_iir_resamplev2;
      .VAR right_op.param[$iir_resamplev2.OBJECT_SIZE] =
           1,
           5,
           0,
           -8,
           8,
           &$cbops.scratch.mem3,
           LENGTH($cbops.scratch.mem3),
           0 ...;
    .ENDBLOCK;

    .BLOCK sw_rate_right_op;
      .VAR sw_rate_right_op.mtu_next = &right_op;
      .VAR sw_rate_right_op.main_next = $cbops.NO_MORE_OPERATORS;
      .VAR sw_rate_right_op.func = &$cbops.rate_adjustment_and_shift;
      .VAR sw_rate_right_op.param[$cbops.rate_adjustment_and_shift.STRUC_SIZE] =
           5,
           3,
           0,
           0,
           &$sra_coeffs,
           &sr_hist_right,
           &sr_hist_right,
           &$sra_struct + $sra.SRA_RATE_FIELD,
           0,
           0 ...;
    .ENDBLOCK;

.ENDMODULE;
.linefile 412 "frontend.asm"
.MODULE $M.dac_out;
   .DATASEGMENT DM;

   .VAR audio_out_timer_struc[$timer.STRUC_SIZE];
   .VAR current_dac_sampling_rate = 48000;
   .VAR dac_sr_flag = 0;

    .VAR/DMCIRC dac_out_left[$OUTPUT_AUDIO_CBUFFER_SIZE]; .VAR left_cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(dac_out_left), &dac_out_left, &dac_out_left;
    .VAR/DMCIRC dac_out_right[$OUTPUT_AUDIO_CBUFFER_SIZE]; .VAR right_cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(dac_out_right), &dac_out_right, &dac_out_right;
    .VAR/DMCIRC Reference.mem[320]; .VAR Reference.cbuffer_struc[$cbuffer.STRUC_SIZE] = LENGTH(Reference.mem), &Reference.mem, &Reference.mem;

   .VAR/DM1CIRC $dither_hist_left[$cbops.dither_and_shift.FILTER_COEFF_SIZE];
   .VAR/DM1CIRC $dither_hist_right[$cbops.dither_and_shift.FILTER_COEFF_SIZE];

   .VAR copy_struc[] =
        $cbops.scratch.BufferTable,
        &insert_op_left,
        &insert_op_left,
        3,
        &left_cbuffer_struc,
        &right_cbuffer_struc,
        &$M.adc_in.sidetone_cbuffer_struc,
        3,
        $AUDIO_LEFT_OUT_PORT,
        $AUDIO_RIGHT_OUT_PORT,
        &Reference.cbuffer_struc,
        0;

    .BLOCK insert_op_left;
        .VAR insert_op_left.prev_op = &insert_op_right;
        .VAR insert_op_left.next_op = &insert_op_right;
        .VAR insert_op_left.func = &$cbops.insert_op;
        .VAR insert_op_left.param[$cbops.insert_op.STRUC_SIZE] =
            0,
            0,
            0 ...;
    .ENDBLOCK;

   .BLOCK insert_op_right;
        .VAR insert_op_right.prev_op = &dac_wrap_op;
        .VAR insert_op_right.next_op = auxillary_mix_right_op;
        .VAR insert_op_right.func = &$cbops.insert_op;
        .VAR insert_op_right.param[$cbops.insert_op.STRUC_SIZE] =
            1,
            0,
            0 ...;
    .ENDBLOCK;

    .BLOCK auxillary_mix_right_op;
        .VAR auxillary_mix_right_op.prev_op = $cbops.NO_MORE_OPERATORS;
        .VAR auxillary_mix_right_op.next_op = &auxillary_mix_left_op;
        .VAR auxillary_mix_right_op.func = &$cbops.aux_audio_mix_op;
        .VAR auxillary_mix_right_op.param[$cbops.aux_audio_mix_op.STRUC_SIZE] =
           1,
           1,
           $TONE_IN_PORT,
           $M.tone_in.right_cbuffer_struc,
           0,
           -128,
           0x80000,
           0x80000,
           0x008000,
           1.0,
           1.0,
           0x40000,
           0,
           1.0,
           0;
   .ENDBLOCK;

    .BLOCK auxillary_mix_left_op;
        .VAR auxillary_mix_left_op.prev_op = auxillary_mix_right_op;
        .VAR auxillary_mix_left_op.next_op = &reference_op;
        .VAR auxillary_mix_left_op.func = &$cbops.aux_audio_mix_op;
        .VAR auxillary_mix_left_op.param[$cbops.aux_audio_mix_op.STRUC_SIZE] =
           0,
           0,
           $TONE_IN_PORT,
           $M.tone_in.left_cbuffer_struc,
           0,
           -128,
           0x80000,
           0x80000,
           0x008000,
           1.0,
           1.0,
           0x40000,
           0,
           1.0,
           0;
   .ENDBLOCK;

    .BLOCK reference_op;
        .VAR reference_op.prev_op = &auxillary_mix_left_op;
        .VAR reference_op.next_op = &sidetone_mix_op;
        .VAR reference_op.func = $cbops_iir_resamplev2;
        .VAR reference_op.param[$iir_resamplev2.OBJECT_SIZE] =
            0,
            5,
            0,
            -8,
            8,
            &$cbops.scratch.mem3,
            LENGTH($cbops.scratch.mem3),
            0 ...;
    .ENDBLOCK;

   .BLOCK sidetone_mix_op;
        .VAR sidetone_mix_op.prev_op = &reference_op;
        .VAR sidetone_mix_op.next_op = &dither_left_op;
        .VAR sidetone_mix_op.func = &$cbops.sidetone_mix_op;
        .VAR sidetone_mix_op.param[$cbops.sidetone_mix_op.STRUC_SIZE] =
            0,
            0,
            2,
            0,
            0;
   .ENDBLOCK;

   .BLOCK dither_left_op;
      .VAR dither_left_op.prev_op = &sidetone_mix_op;
      .VAR dither_left_op.next_op = &dither_right_op;
      .VAR dither_left_op.func = &$cbops.dither_and_shift;
      .VAR dither_left_op.param[$cbops.dither_and_shift.STRUC_SIZE] =
            0,
            3,
            -8,
            $cbops.dither_and_shift.DITHER_TYPE_NONE,
            $dither_hist_left,
            0;
   .ENDBLOCK;

   .BLOCK dither_right_op;
      .VAR dither_right_op.prev_op = &dither_left_op;
      .VAR dither_right_op.next_op = &dac_wrap_op;
      .VAR dither_right_op.func = &$cbops.dither_and_shift;
      .VAR dither_right_op.param[$cbops.dither_and_shift.STRUC_SIZE] =
            1,
            4,
            -8,
            $cbops.dither_and_shift.DITHER_TYPE_NONE,
            $dither_hist_right,
            0;
   .ENDBLOCK;

    .BLOCK dac_wrap_op;
        .VAR dac_wrap_op.prev_op = &dither_right_op;
        .VAR dac_wrap_op.next_op = $cbops.NO_MORE_OPERATORS;
        .VAR dac_wrap_op.func = &$cbops.port_wrap_op;
        .VAR dac_wrap_op.param[$cbops.port_wrap_op.STRUC_SIZE] =
            3,
            4,
            3,
            0,
            1,
            0;
    .ENDBLOCK;

.ENDMODULE;
.linefile 581 "frontend.asm"
.MODULE $M.audio_out_copy_handler;
   .CODESEGMENT AUDIO_OUT_COPY_HANDLER_PM;
   .DATASEGMENT DM;

$audio_out_copy_handler:


   push rLink;


   M[$frame_sync.sync_flag] = Null;


   Null = M[$M.dac_out.dac_sr_flag];
   if NZ call $ConfigureFrontEnd;


   Null = M[$M.A2DP_IN.codec_sr_flag];
   if NZ call $ConfigureFrontEnd;

   r0 = M[&$M.tone_in.left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.detect_end_of_aux_stream.last_write_address] = r0;


   r8 = &$M.adc_in.copy_struc;
   call $cbops_multirate.copy;


   r8 = &$M.tone_in.copy_struc;
   call $cbops_multirate.copy;


   call $detect_end_of_aux_stream;


   r8 = &$M.dac_out_resample.copy_struc;
   call $cbops_multirate.copy;







   r8 = &$M.dac_out.copy_struc;
   call $cbops_multirate.copy;


   r1 = &$M.dac_out.audio_out_timer_struc;
   r2 = 750;
   r3 = &$audio_out_copy_handler;
   call $timer.schedule_event_in_period;


   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 650 "frontend.asm"
.MODULE $M.FrontEndConfigure;
   .CODESEGMENT AUDIO_OUT_COPY_HANDLER_PM;
   .DATASEGMENT DM;

$FrontEndStart:

push rLink;


    r1 = &$M.dac_out.audio_out_timer_struc;
    r2 = 750;
    r3 = &$audio_out_copy_handler;
    call $timer.schedule_event_in;


jump $pop_rLink_and_rts;

$ConfigureFrontEnd:


   push rLink;

    M[$M.dac_out.dac_sr_flag] = NULL;
    M[$M.A2DP_IN.codec_sr_flag] = Null;

    r1 = 48000;
    Null = r1 - M[$M.dac_out.current_dac_sampling_rate];
    if NZ jump check_dac_chain_44k;

    r3 = 44100;
    Null = r3 - M[$M.set_codec_rate.current_codec_sampling_rate];
    if NZ jump set_dac_chain_48k;


    r0 = &$M.iir_resamplev2.Up_160_Down_147_low_mips.filter;
    r8 = &$M.dac_out_resample.left_op.param;
    call $iir_resamplev2.SetFilter;


    r0 = &$M.iir_resamplev2.Up_160_Down_147_low_mips.filter;
    r8 = &$M.dac_out_resample.right_op.param;
    call $iir_resamplev2.SetFilter;

set_dac_chain_48k:


    r0 = &$M.iir_resamplev2.Up_3_Down_1.filter;
    r8 = &$M.adc_in.sidetone_resample_op.param;
    call $iir_resamplev2.SetFilter;


    r0 = &$M.iir_resamplev2.Up_1_Down_3.filter;
    r8 = &$M.dac_out.reference_op.param;
    call $iir_resamplev2.SetFilter;

    jump set_max_advance_fields;

check_dac_chain_44k:

    r4 = 48000;
    Null = r4 - M[$M.set_codec_rate.current_codec_sampling_rate];
    if NZ jump set_dac_chain_44k;


    r0 = &$M.iir_resamplev2.Up_147_Down_160_low_mips.filter;
    r8 = &$M.dac_out_resample.left_op.param;
    call $iir_resamplev2.SetFilter;


    r0 = &$M.iir_resamplev2.Up_147_Down_160_low_mips.filter;
    r8 = &$M.dac_out_resample.right_op.param;
    call $iir_resamplev2.SetFilter;

set_dac_chain_44k:


    r0 = &$M.iir_resamplev2.Up_441_Down_160.filter;
    r8 = &$M.adc_in.sidetone_resample_op.param;
    call $iir_resamplev2.SetFilter;


    r0 = &$M.iir_resamplev2.Up_160_Down_441.filter;
    r8 = &$M.dac_out.reference_op.param;
    call $iir_resamplev2.SetFilter;

set_max_advance_fields:

    r1 = M[$M.dac_out.current_dac_sampling_rate];
    r2 = r1 * $ADCDAC_PERIOD_USEC (frac);
    r2 = r2 + 1;

    M[$M.dac_out.sidetone_mix_op.param + $cbops.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD]=r2;
    M[$M.dac_out.dac_wrap_op.param + $cbops.port_wrap_op.MAX_ADVANCE_FIELD] = r2;
    M[$M.dac_out.insert_op_left.param + $cbops.insert_op.MAX_ADVANCE_FIELD] = r2;
    M[$M.dac_out.insert_op_right.param + $cbops.insert_op.MAX_ADVANCE_FIELD] = r2;


   jump $pop_rLink_and_rts;

.ENDMODULE;






.MODULE $M.master_app_reset;
   .CODESEGMENT MASTER_APP_RESET_PM;
   .DATASEGMENT DM;
   $master_app_reset:


push rLink;


   Null = M[&$M.set_dac_rate.local_play_back];
   if Z jump pause_happened;


   r2 = 0x1080;
   r3 = 0;
   r4 = 0;
   r5 = 0;
   r6 = 0;
   call $message.send_short;
   pause_happened:

   call $block_interrupts;


   r0 = M[&$M.dac_out.left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.dac_out.left_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;

   r0 = M[&$M.dac_out.right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.dac_out.right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;


   r0 = M[&$M.dac_out_resample.left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.dac_out_resample.left_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;

   r0 = M[&$M.dac_out_resample.right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.dac_out_resample.right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;







   call $unblock_interrupts;


jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 813 "frontend.asm"
.MODULE $M.detect_end_of_aux_stream;
   .CODESEGMENT DETECT_END_OF_AUX_STREAM_PM;
   .DATASEGMENT DM;

   .VAR last_write_address = &$M.tone_in.left_mem;
   .VAR write_move_counter = 0;

   $detect_end_of_aux_stream:

   push rLink;


   r3 = M[$M.tone_in.aux_input_stream_available];
   if Z jump $pop_rLink_and_rts;


   r0 = $M.tone_in.left_cbuffer_struc;
   call $cbuffer.calc_amount_data;


   Null = r3 AND 0x2;
   if NZ jump input_has_received;


   Null = r0;
   if Z jump $pop_rLink_and_rts;


   r3 = r3 OR 0x2;
   M[$M.tone_in.aux_input_stream_available] = r3;
   jump $pop_rLink_and_rts;

   input_has_received:


   r0 = &$M.tone_in.left_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   r4 = M[last_write_address];
   r3 = M[write_move_counter];
   r5 = 0;

   Null = r0 - r4;
   if Z r5 = r3 + 1;
   M[write_move_counter] = r5;

   Null = r5 - 40;
   if NEG jump $pop_rLink_and_rts;



   r2 = 0x1080;
   r3 = 0;
   r4 = 0;
   r5 = 0;
   r6 = 0;
   call $message.send_short;
   M[$M.tone_in.aux_input_stream_available] = 0;
   M[write_move_counter] = 0;


   r0 = M[&$M.tone_in.left_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.tone_in.left_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;

   r0 = M[&$M.tone_in.right_cbuffer_struc + $cbuffer.WRITE_ADDR_FIELD];
   M[&$M.tone_in.right_cbuffer_struc + $cbuffer.READ_ADDR_FIELD] = r0;


   jump $pop_rLink_and_rts;
.ENDMODULE;
.linefile 898 "frontend.asm"
.MODULE $M.set_tone_rate;
   .CODESEGMENT SET_TONE_RATE_PM;
   .DATASEGMENT DM;

   func:

   push rLink;


   r3 = $M.tone_in.copy_left_to_right;
   r4 = $M.tone_in.shift_op_right;
   r0 = r2 AND 1;
   M[$M.tone_in.deinterleave_mix_op.param + $cbops.deinterleave_mix.INPUT_INTERLEAVED_FIELD] = r0;



   if NZ r3 = r4;
   M[$M.tone_in.copy_op_left.next_op] = r3;


   r0 = 8 + (-1);
   r3 = 8 + 2;
   Null = r2 AND 0x2;
   if Z r0 = r3;
   M[$M.tone_in.shift_op_left.param + $cbops.shift.SHIFT_AMOUNT_FIELD] = r0;
   M[$M.tone_in.shift_op_right.param + $cbops.shift.SHIFT_AMOUNT_FIELD] = r0;


   r1 = r1 AND 0xFFFF;
   M[$M.tone_in.current_tone_sampling_rate] = r1;


   r0 = $M.tone_in.left_cbuffer_struc;
   call $cbuffer.empty_buffer;
   r0 = $M.tone_in.right_cbuffer_struc;
   call $cbuffer.empty_buffer;


   r10 = length($M.tone_in.tone_hist_left);
   r0 = 0;
   I2 = $M.tone_in.tone_hist_left;
   I6 = $M.tone_in.tone_hist_right;
   do clear_loop;
      M[I2, 1] = r0, M[I6,1] = r0;
   clear_loop:


   r0 = 1;
   M[$M.tone_in.aux_input_stream_available] = r0;


   jump $pop_rLink_and_rts;

.ENDMODULE;
