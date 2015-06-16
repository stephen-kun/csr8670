.linefile 1 "sr_adjustment_gaming.asm"
.linefile 1 "<command-line>"
.linefile 1 "sr_adjustment_gaming.asm"







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
.linefile 9 "sr_adjustment_gaming.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_library.h" 1
.linefile 9 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_library.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h"
   .CONST $cbops.MAX_NUM_CHANNELS 16;
   .CONST $cbops.NO_MORE_OPERATORS -1;
   .CONST $cbops.MAX_OPERATORS 10;
   .CONST $cbops.MAX_COPY_SIZE 512;



   .CONST $cbops.OPERATOR_STRUC_ADDR_FIELD 0;
   .CONST $cbops.NUM_INPUTS_FIELD 1;




   .CONST $cbops.NEXT_OPERATOR_ADDR_FIELD 0;
   .CONST $cbops.FUNCTION_VECTOR_FIELD 1;
   .CONST $cbops.PARAMETER_AREA_START_FIELD 2;
   .CONST $cbops.STRUC_SIZE 3;



.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_vector_table.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_vector_table.h"
   .CONST $cbops.function_vector.RESET_FIELD 0;
   .CONST $cbops.function_vector.AMOUNT_TO_USE_FIELD 1;
   .CONST $cbops.function_vector.MAIN_FIELD 2;
   .CONST $cbops.function_vector.STRUC_SIZE 3;

   .CONST $cbops.function_vector.NO_FUNCTION 0;
.linefile 34 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_dc_remove.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_dc_remove.h"
   .CONST $cbops.dc_remove.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.dc_remove.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.dc_remove.DC_ESTIMATE_FIELD 2;
   .CONST $cbops.dc_remove.STRUC_SIZE 3;





   .CONST $cbops.dc_remove.FILTER_COEF 0.0003;
.linefile 37 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_limited_copy.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_limited_copy.h"
   .CONST $cbops.limited_copy.READ_LIMIT_FIELD 0;
   .CONST $cbops.limited_copy.WRITE_LIMIT_FIELD 1;
   .CONST $cbops.limited_copy.STRUC_SIZE 2;

   .CONST $cbops.limited_copy.NO_READ_LIMIT -1;
   .CONST $cbops.limited_copy.NO_WRITE_LIMIT -1;
.linefile 40 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_fill_limit.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_fill_limit.h"
   .CONST $cbops.fill_limit.FILL_LIMIT_FIELD 0;
   .CONST $cbops.fill_limit.OUT_BUFFER_FIELD 1;
   .CONST $cbops.fill_limit.STRUC_SIZE 2;
   .CONST $cbops.fill_limit.NO_LIMIT -1;
.linefile 43 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_noise_gate.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_noise_gate.h"
   .CONST $cbops.noise_gate.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.noise_gate.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.noise_gate.MONOSTABLE_COUNT_FIELD 2;
   .CONST $cbops.noise_gate.DECAYATTACK_COUNT_FIELD 3;
   .CONST $cbops.noise_gate.STRUC_SIZE 4;
.linefile 46 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_shift.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_shift.h"
   .CONST $cbops.shift.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.shift.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.shift.SHIFT_AMOUNT_FIELD 2;
   .CONST $cbops.shift.STRUC_SIZE 3;
.linefile 49 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_sidetone_mix.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_sidetone_mix.h"
   .CONST $cbops.sidetone_mix.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.sidetone_mix.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.sidetone_mix.SIDETONE_BUFFER_FIELD 2;
   .CONST $cbops.sidetone_mix.SIDETONE_MAX_SAMPLES_FIELD 3;
   .CONST $cbops.sidetone_mix.GAIN_FIELD 4;
   .CONST $cbops.sidetone_mix.STRUC_SIZE 5;
.linefile 52 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_silence_clip_detect.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_silence_clip_detect.h"
   .CONST $cbops.silence_clip_detect.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.silence_clip_detect.INSTANCE_NO_FIELD 1;
   .CONST $cbops.silence_clip_detect.SILENCE_LIMIT_FIELD 2;
   .CONST $cbops.silence_clip_detect.CLIP_LIMIT_FIELD 3;
   .CONST $cbops.silence_clip_detect.SILENCE_PERIOD_LSW_FIELD 4;
   .CONST $cbops.silence_clip_detect.SILENCE_PERIOD_MSW_FIELD 5;
   .CONST $cbops.silence_clip_detect.PREVIOUS_TIME_FIELD 6;
   .CONST $cbops.silence_clip_detect.SILENCE_AMOUNT_LSW_FIELD 7;
   .CONST $cbops.silence_clip_detect.SILENCE_AMOUNT_MSW_FIELD 8;
   .CONST $cbops.silence_clip_detect.STRUC_SIZE 9;

   .CONST $cbops.silence_clip_detect.LOOK_UP_SIZE 8;
.linefile 55 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_upsample_mix.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_upsample_mix.h"
   .CONST $cbops.upsample_mix.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.upsample_mix.TONE_SOURCE_FIELD 2;
   .CONST $cbops.upsample_mix.TONE_VOL_FIELD 3;
   .CONST $cbops.upsample_mix.AUDIO_VOL_FIELD 4;
   .CONST $cbops.upsample_mix.RESAMPLE_COEFS_ADDR_FIELD 5;
   .CONST $cbops.upsample_mix.RESAMPLE_COEFS_SIZE_FIELD 6;
   .CONST $cbops.upsample_mix.RESAMPLE_BUFFER_ADDR_FIELD 7;
   .CONST $cbops.upsample_mix.RESAMPLE_BUFFER_SIZE_FIELD 8;
   .CONST $cbops.upsample_mix.UPSAMPLE_RATIO_FIELD 9;
   .CONST $cbops.upsample_mix.INTERP_RATIO_FIELD 10;
   .CONST $cbops.upsample_mix.INTERP_COEF_CURRENT_FIELD 11;
   .CONST $cbops.upsample_mix.INTERP_LAST_VAL_FIELD 12;
   .CONST $cbops.upsample_mix.TONE_PLAYING_STATE_FIELD 13;
   .CONST $cbops.upsample_mix.TONE_DATA_AMOUNT_READ_FIELD 14;
   .CONST $cbops.upsample_mix.TONE_DATA_AMOUNT_FIELD 15;
   .CONST $cbops.upsample_mix.LOCATION_IN_LOOP_FIELD 16;
   .CONST $cbops.upsample_mix.STRUC_SIZE 17;



   .CONST $cbops.upsample_mix.TONE_START_LEVEL 118;





   .CONST $cbops.upsample_mix.TONE_BLOCK_SIZE 72;

   .CONST $cbops.upsample_mix.TONE_PLAYING_STATE_STOPPED 0;
   .CONST $cbops.upsample_mix.TONE_PLAYING_STATE_PLAYING 1;

   .CONST $cbops.upsample_mix.NO_BUFFER -1;



   .CONST $cbops.upsample_mix.RESAMPLE_BUFFER_LENGTH_HIGH_QUALITY 10;



   .CONST $cbops.upsample_mix.RESAMPLE_BUFFER_LENGTH_LOW_QUALITY 4;
.linefile 58 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_volume.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_volume.h"
   .CONST $cbops.volume.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.volume.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.volume.FINAL_VALUE_FIELD 2;
   .CONST $cbops.volume.CURRENT_VALUE_FIELD 3;
   .CONST $cbops.volume.SAMPLES_PER_STEP_FIELD 4;
   .CONST $cbops.volume.STEP_SHIFT_FIELD 5;
   .CONST $cbops.volume.DELTA_FIELD 6;
   .CONST $cbops.volume.CURRENT_STEP_FIELD 7;
   .CONST $cbops.volume.STRUC_SIZE 8;
.linefile 61 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_volume_basic.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_volume_basic.h"
   .CONST $cbops.volume_basic.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.volume_basic.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.volume_basic.FINAL_VALUE_FIELD 2;
   .CONST $cbops.volume_basic.CURRENT_VALUE_FIELD 3;
   .CONST $cbops.volume_basic.SMOOTHING_VALUE_FIELD 4;
   .CONST $cbops.volume_basic.DELTA_THRESHOLD_VALUE_FIELD 5;
   .CONST $cbops.volume_basic.STRUC_SIZE 6;
.linefile 64 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_warp_and_shift.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_warp_and_shift.h"
   .CONST $cbops.warp_and_shift.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.warp_and_shift.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.warp_and_shift.SHIFT_AMOUNT_FIELD 2;
   .CONST $cbops.warp_and_shift.FILT_COEFS_ADDR_FIELD 3;
   .CONST $cbops.warp_and_shift.DATA_TAPS_ADDR_FIELD 4;




   .CONST $cbops.warp_and_shift.WARP_TARGET_ADDR_FIELD $cbops.warp_and_shift.DATA_TAPS_ADDR_FIELD + 1;

   .CONST $cbops.warp_and_shift.WARP_MAX_RAMP_FIELD $cbops.warp_and_shift.WARP_TARGET_ADDR_FIELD + 1;
   .CONST $cbops.warp_and_shift.CURRENT_WARP_FIELD $cbops.warp_and_shift.WARP_MAX_RAMP_FIELD + 1;
   .CONST $cbops.warp_and_shift.CURRENT_WARP_COEF_FIELD $cbops.warp_and_shift.CURRENT_WARP_FIELD + 1;
   .CONST $cbops.warp_and_shift.CURRENT_FILT_COEF_ADDR_FIELD $cbops.warp_and_shift.CURRENT_WARP_COEF_FIELD + 1;
   .CONST $cbops.warp_and_shift.CURRENT_SAMPLE_A_FIELD $cbops.warp_and_shift.CURRENT_FILT_COEF_ADDR_FIELD + 1;
   .CONST $cbops.warp_and_shift.PREVIOUS_STATE_FIELD $cbops.warp_and_shift.CURRENT_SAMPLE_A_FIELD + 1;
   .CONST $cbops.warp_and_shift.STRUC_SIZE $cbops.warp_and_shift.PREVIOUS_STATE_FIELD + 1;

   .CONST $cbops.warp_and_shift.filt_coefs.L_FIELD 0;
   .CONST $cbops.warp_and_shift.filt_coefs.R_FIELD 1;
   .CONST $cbops.warp_and_shift.filt_coefs.INV_R_FIELD 2;
   .CONST $cbops.warp_and_shift.filt_coefs.COEFS_FIELD 3;
.linefile 67 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_deinterleave.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_deinterleave.h"
   .CONST $cbops.deinterleave.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.deinterleave.OUTPUT1_START_INDEX_FIELD 1;
   .CONST $cbops.deinterleave.OUTPUT2_START_INDEX_FIELD 2;
   .CONST $cbops.deinterleave.SHIFT_AMOUNT_FIELD 3;
   .CONST $cbops.deinterleave.STRUC_SIZE 4;
.linefile 70 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_rate_adjustment_and_shift.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_rate_adjustment_and_shift.h"
   .CONST $cbops.rate_adjustment_and_shift.INPUT1_START_INDEX_FIELD 0;
   .CONST $cbops.rate_adjustment_and_shift.OUTPUT1_START_INDEX_FIELD 1;
   .CONST $cbops.rate_adjustment_and_shift.INPUT2_START_INDEX_FIELD 2;
   .CONST $cbops.rate_adjustment_and_shift.OUTPUT2_START_INDEX_FIELD 3;
   .CONST $cbops.rate_adjustment_and_shift.SHIFT_AMOUNT_FIELD 4;
   .CONST $cbops.rate_adjustment_and_shift.FILTER_COEFFS_FIELD 5;
   .CONST $cbops.rate_adjustment_and_shift.HIST1_BUF_FIELD 6;
   .CONST $cbops.rate_adjustment_and_shift.HIST2_BUF_FIELD 7;





   .CONST $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD $cbops.rate_adjustment_and_shift.HIST2_BUF_FIELD+1;

   .CONST $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD+1;
   .CONST $cbops.rate_adjustment_and_shift.ENABLE_COMPRESSOR_FIELD $cbops.rate_adjustment_and_shift.DITHER_TYPE_FIELD+1;
   .CONST $cbops.rate_adjustment_and_shift.FILTER_COEFFS_SIZE_FIELD $cbops.rate_adjustment_and_shift.ENABLE_COMPRESSOR_FIELD+1;
   .CONST $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD $cbops.rate_adjustment_and_shift.FILTER_COEFFS_SIZE_FIELD+1;
   .CONST $cbops.rate_adjustment_and_shift.RF $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD+1;
   .CONST $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD $cbops.rate_adjustment_and_shift.RF+1;
   .CONST $cbops.rate_adjustment_and_shift.WORKING_STATE_FIELD $cbops.rate_adjustment_and_shift.PREV_SHORT_SAMPLES_FIELD+1;
   .CONST $cbops.rate_adjustment_and_shift.DITHER_HIST_LEFT_INDEX_FIELD $cbops.rate_adjustment_and_shift.WORKING_STATE_FIELD+1;
   .CONST $cbops.rate_adjustment_and_shift.DITHER_HIST_RIGHT_INDEX_FIELD $cbops.rate_adjustment_and_shift.DITHER_HIST_LEFT_INDEX_FIELD+1;

   .CONST $cbops.rate_adjustment_and_shift.STRUC_SIZE $cbops.rate_adjustment_and_shift.DITHER_HIST_RIGHT_INDEX_FIELD+1;


   .CONST $cbops.rate_adjustment_and_shift_complete.STRUC_SIZE 1;

   .CONST $cbops.rate_adjustment_and_shift.SRA_UPRATE 21;

   .CONST $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE 12;
   .CONST $cbops.rate_adjustment_and_shift.SRA_HD_QUALITY_COEFFS_SIZE 36;

  .CONST $sra.MOVING_STEP (0.0015*(1.0/1000.0)/10.0);
.linefile 73 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_one_to_two_chan_copy.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_one_to_two_chan_copy.h"
   .CONST $cbops.one_to_two_chan_copy.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.one_to_two_chan_copy.OUTPUT_A_START_INDEX_FIELD 1;
   .CONST $cbops.one_to_two_chan_copy.OUTPUT_B_START_INDEX_FIELD 2;
   .CONST $cbops.one_to_two_chan_copy.STRUC_SIZE 3;
.linefile 76 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_copy_op.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_copy_op.h"
   .CONST $cbops.copy_op.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.copy_op.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.copy_op.STRUC_SIZE 2;
.linefile 79 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_compress_copy_op.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_compress_copy_op.h"
   .CONST $cbops.compress_copy_op.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.compress_copy_op.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.compress_copy_op.SHIFT_AMOUNT 2;
   .CONST $cbops.compress_copy_op.STRUC_SIZE 3;

   .CONST $COMPRESS_RANGE 0.1087;
.linefile 82 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_mix.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_mix.h"
   .CONST $cbops.mix.MIX_SOURCE_FIELD 0;
   .CONST $cbops.mix.MIX_VOL_FIELD 1;
   .CONST $cbops.mix.AUDIO_VOL_FIELD 2;
   .CONST $cbops.mix.MIXING_STATE_FIELD 3;
   .CONST $cbops.mix.MIXING_START_LEVEL_FIELD 4;
   .CONST $cbops.mix.NUMBER_OF_INPUTS_FIELD 5;
   .CONST $cbops.mix.INPUT_START_INDEX_FIELD 6;




   .CONST $cbops.mix.MIX_INPUT_START_LEVEL 118;

   .CONST $cbops.mix.MIXING_STATE_STOPPED 0;
   .CONST $cbops.mix.MIXING_STATE_MIXING 1;
.linefile 85 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_mono_to_stereo.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_mono_to_stereo.h"
   .CONST $cbops.mono_to_stereo.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.mono_to_stereo.OUTPUT_1_START_INDEX_FIELD 1;
   .CONST $cbops.mono_to_stereo.OUTPUT_2_START_INDEX_FIELD 2;
   .CONST $cbops.mono_to_stereo.DELAY_BUF_INDEX_FIELD 3;
   .CONST $cbops.mono_to_stereo.RATIO 4;
   .CONST $cbops.mono_to_stereo.STRUC_SIZE 5;
.linefile 88 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_stereo_3d_enhance_op.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_stereo_3d_enhance_op.h"
   .CONST $cbops.stereo_3d_enhance_op.INPUT_1_START_INDEX_FIELD 0;
   .CONST $cbops.stereo_3d_enhance_op.INPUT_2_START_INDEX_FIELD 1;
   .CONST $cbops.stereo_3d_enhance_op.OUTPUT_1_START_INDEX_FIELD 2;
   .CONST $cbops.stereo_3d_enhance_op.OUTPUT_2_START_INDEX_FIELD 3;
   .CONST $cbops.stereo_3d_enhance_op.DELAY_1_STRUC_FIELD 4;
   .CONST $cbops.stereo_3d_enhance_op.DELAY_2_STRUC_FIELD 5;
   .CONST $cbops.stereo_3d_enhance_op.COEF_STRUC_FIELD 6;
   .CONST $cbops.stereo_3d_enhance_op.REFLECTION_DELAY_SAMPLES_FIELD 7;
   .CONST $cbops.stereo_3d_enhance_op.STRUC_SIZE 8;

   .CONST $cbops.stereo_3d_enhance_op.REFLECTION_DELAY 618;
.linefile 91 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_status_check_gain.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_status_check_gain.h"
   .CONST $cbops.status_check_gain.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.status_check_gain.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.status_check_gain.GAIN_ADDRESS_FIELD 2;
   .CONST $cbops.status_check_gain.PORT_ADDRESS_FIELD 3;
   .CONST $cbops.status_check_gain.STRUC_SIZE 4;
.linefile 94 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_scale.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_scale.h"
   .CONST $cbops.scale.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.scale.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.scale.PRE_INT_AMOUNT_FIELD 2;
   .CONST $cbops.scale.FRAC_AMOUNT_FIELD 3;
   .CONST $cbops.scale.POST_INT_AMOUNT_FIELD 4;
   .CONST $cbops.scale.STRUC_SIZE 5;
.linefile 97 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_two_to_one_chan_copy.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_two_to_one_chan_copy.h"
   .CONST $cbops.two_to_one_chan_copy.INPUT_A_START_INDEX_FIELD 0;
   .CONST $cbops.two_to_one_chan_copy.INPUT_B_START_INDEX_FIELD 1;
   .CONST $cbops.two_to_one_chan_copy.OUTPUT_B_START_INDEX_FIELD 2;
   .CONST $cbops.two_to_one_chan_copy.INPUT_A_GAIN_FIELD 3;
   .CONST $cbops.two_to_one_chan_copy.INPUT_B_GAIN_FIELD 4;

   .CONST $cbops.two_to_one_chan_copy.STRUC_SIZE 5;
.linefile 100 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_eq.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_eq.h"
   .CONST $cbops.eq.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.eq.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.eq.PTR_DELAY_LINE_FIELD 2;
   .CONST $cbops.eq.PTR_COEFS_BUFF_FIELD 3;
   .CONST $cbops.eq.NUM_STAGES_FIELD 4;
   .CONST $cbops.eq.DELAY_BUF_SIZE 5;
   .CONST $cbops.eq.COEFF_BUF_SIZE 6;
   .CONST $cbops.eq.BLOCK_SIZE_FIELD 7;
   .CONST $cbops.eq.PTR_SCALE_BUFF_FIELD 8;
   .CONST $cbops.eq.INPUT_GAIN_EXPONENT_PTR 9;
   .CONST $cbops.eq.INPUT_GAIN_MANTISA_PTR 10;
   .CONST $cbops.eq.STRUC_SIZE 11;
.linefile 103 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/resample/resample_header.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/resample/resample_header.h"
   .CONST $cbops.resample.INPUT_1_START_INDEX_FIELD 0;
   .CONST $cbops.resample.INPUT_2_START_INDEX_FIELD 1;
   .CONST $cbops.resample.OUTPUT_1_START_INDEX_FIELD 2;
   .CONST $cbops.resample.OUTPUT_2_START_INDEX_FIELD 3;
   .CONST $cbops.resample.COEF_BUF_INDEX_FIELD 4;
   .CONST $cbops.resample.CONVERT_RATIO_INT_FIELD 5;
   .CONST $cbops.resample.CONVERT_RATIO_FRAC_FIELD 6;
   .CONST $cbops.resample.INV_CONVERT_RATIO_FIELD 7;
   .CONST $cbops.resample.RATIO_IN_FIELD 8;
   .CONST $cbops.resample.RATIO_OUT_FIELD 9;
   .CONST $cbops.resample.STRUC_SIZE 10;


   .CONST $cbops.auto_resample_mix.IO_LEFT_INDEX_FIELD 0;
   .CONST $cbops.auto_resample_mix.IO_RIGHT_INDEX_FIELD 1;
   .CONST $cbops.auto_resample_mix.TONE_CBUFFER_FIELD 2;
   .CONST $cbops.auto_resample_mix.COEF_BUF_INDEX_FIELD 3;
   .CONST $cbops.auto_resample_mix.OUTPUT_RATE_ADDR_FIELD 4;
   .CONST $cbops.auto_resample_mix.HIST_BUF_FIELD 5;
   .CONST $cbops.auto_resample_mix.INPUT_RATE_ADDR_FIELD 6;
   .CONST $cbops.auto_resample_mix.TONE_MIXING_RATIO_FIELD 7;
   .CONST $cbops.auto_resample_mix.AUDIO_MIXING_RATIO_FIELD 8;
   .CONST $cbops.auto_resample_mix.CONVERT_RATIO_FRAC_FIELD 9;
   .CONST $cbops.auto_resample_mix.CURRENT_OUTPUT_RATE_FIELD 10;
   .CONST $cbops.auto_resample_mix.CURRENT_INPUT_RATE_FIELD 11;
   .CONST $cbops.auto_resample_mix.CONVERT_RATIO_INT_FIELD 12;
   .CONST $cbops.auto_resample_mix.IR_RATIO_FIELD 13;
   .CONST $cbops.auto_resample_mix.SOFT_MOVE_GAIN_FIELD 14;
   .CONST $cbops.auto_resample_mix.INPUT_STATE_FIELD 15;
   .CONST $cbops.auto_resample_mix.INPUT_COUNTER_FIELD 16;
   .CONST $cbops.auto_resample_mix.OPERATION_MODE_FIELD 17;
   .CONST $cbops.auto_resample_mix.STRUC_SIZE 18;


   .CONST $cbops.auto_resample_mix.TONE_MIXING_NOTONE_STATE 0;
   .CONST $cbops.auto_resample_mix.TONE_MIXING_NORMAL_STATE 1;


   .CONST $cbops.auto_resample_mix.TONE_MIXING_RESAMPLE_ACTION 0;
   .CONST $cbops.auto_resample_mix.TONE_MIXING_IGNORE_ACTION 1;
   .CONST $cbops.auto_resample_mix.TONE_MIXING_JUSTMIX_ACTION 2;


   .CONST $cbops.auto_resample_mix.TONE_FILTER_HIST_LENGTH $cbops.rate_adjustment_and_shift.SRA_COEFFS_SIZE;
   .CONST $cbops.auto_resample_mix.TONE_FILTER_UPRATE $cbops.rate_adjustment_and_shift.SRA_UPRATE;
.linefile 105 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_dither_and_shift.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_dither_and_shift.h"
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
.linefile 107 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_univ_mix_op.h" 1
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_univ_mix_op.h"
   .CONST $cbops.univ_mix_op.INPUT_START_INDEX_FIELD 0;
   .CONST $cbops.univ_mix_op.OUTPUT_START_INDEX_FIELD 1;
   .CONST $cbops.univ_mix_op.MIXER_PRIMARY_COPY_STRUCT_ADDR_FIELD 2;
   .CONST $cbops.univ_mix_op.MIXER_SECONDARY_COPY_STRUCT_ADDR_FIELD 3;
   .CONST $cbops.univ_mix_op.COMMON_PARAM_STRUCT_ADDR_FIELD 4;
   .CONST $cbops.univ_mix_op.PRIMARY_UPSAMPLER_STRUCT_ADDR_FIELD 5;
   .CONST $cbops.univ_mix_op.SECONDARY_UPSAMPLER_STRUCT_ADDR_FIELD 6;
   .CONST $cbops.univ_mix_op.OUTPUT_UPSAMPLER_STRUCT_ADDR_FIELD 7;

   .CONST $cbops.univ_mix_op.STRUC_SIZE 8;





   .CONST $cbops.univ_mix_op.common.CHANNELS_ACTIVITY_FIELD 0;

   .CONST $cbops.univ_mix_op.common.STRUC_SIZE 1;
.linefile 44 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_univ_mix_op.h"
   .CONST $cbops.univ_mix_op.params.INPUT_GAIN_FACTOR_FIELD 0;
   .CONST $cbops.univ_mix_op.params.INPUT_GAIN_SHIFT_FIELD 1;


   .CONST $cbops.univ_mix_op.params.RAMP_GAIN_WHEN_MIXING_FIELD 2;
   .CONST $cbops.univ_mix_op.params.TARGET_RAMP_GAIN_ADJUST_FIELD 3;
   .CONST $cbops.univ_mix_op.params.NUM_RAMP_SAMPLES_FIELD 4;
   .CONST $cbops.univ_mix_op.params.RAMP_STEP_SHIFT_FIELD 5;
   .CONST $cbops.univ_mix_op.params.RAMP_DELTA_FIELD 6;


   .CONST $cbops.univ_mix_op.params.UPSAMPLING_FACTOR_FIELD 7;
   .CONST $cbops.univ_mix_op.params.INPUT_RATE_FIELD 8;
   .CONST $cbops.univ_mix_op.params.INVERSE_INPUT_RATE_FIELD 9;
   .CONST $cbops.univ_mix_op.params.OUTPUT_RATE_FIELD 10;
   .CONST $cbops.univ_mix_op.params.INTERP_PHASE_STEP_FIELD 11;


   .CONST $cbops.univ_mix_op.params.RESAMPLE_COEFS_ADDR_FIELD 12;
   .CONST $cbops.univ_mix_op.params.RESAMPLE_COEFS_SIZE_FIELD 13;
   .CONST $cbops.univ_mix_op.params.RESAMPLE_BUFFER_SIZE_FIELD 14;

   .CONST $cbops.univ_mix_op.params.STRUC_SIZE 15;
.linefile 78 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_univ_mix_op.h"
   .CONST $cbops.univ_mix_op.data.PARAMETER_ADDR_FIELD 0;


   .CONST $cbops.univ_mix_op.data.INPUT_BUFFER_ADDR_FIELD 1;
   .CONST $cbops.univ_mix_op.data.INPUT_BUFFER_LENGTH_FIELD 2;
   .CONST $cbops.univ_mix_op.data.OUTPUT_BUFFER_ADDR_FIELD 3;
   .CONST $cbops.univ_mix_op.data.OUTPUT_BUFFER_LENGTH_FIELD 4;


   .CONST $cbops.univ_mix_op.data.INPUT_SAMPLES_REQUESTED_FIELD 5;
   .CONST $cbops.univ_mix_op.data.OUTPUT_SAMPLES_REQUESTED_FIELD 6;


   .CONST $cbops.univ_mix_op.data.INPUT_SAMPLES_READ_FIELD 7;
   .CONST $cbops.univ_mix_op.data.OUTPUT_SAMPLES_WRITTEN_FIELD 8;


   .CONST $cbops.univ_mix_op.data.RAMP_ACTIVE_FIELD 9;
   .CONST $cbops.univ_mix_op.data.CURRENT_RAMP_GAIN_ADJUST_FIELD 10;
   .CONST $cbops.univ_mix_op.data.CURRENT_RAMP_SAMPLE_COUNT_FIELD 11;
   .CONST $cbops.univ_mix_op.data.RAMP_CALLBACK_FIELD 12;


   .CONST $cbops.univ_mix_op.data.RESAMPLE_BUFFER_ADDR_FIELD 13;


   .CONST $cbops.univ_mix_op.data.INTERP_CURRENT_PHASE_FIELD 14;
   .CONST $cbops.univ_mix_op.data.INTERP_LAST_VAL_FIELD 15;
   .CONST $cbops.univ_mix_op.data.LOCATION_IN_LOOP_FIELD 16;

   .CONST $cbops.univ_mix_op.data.STRUC_SIZE 17;
.linefile 117 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_univ_mix_op.h"
   .CONST $cbops.univ_mix_op.common.NO_CHANNELS_ACTIVE (0x000000);
   .CONST $cbops.univ_mix_op.common.PRIMARY_CHANNEL_ACTIVE (0x000001);
   .CONST $cbops.univ_mix_op.common.SECONDARY_CHANNEL_ACTIVE (0x000002);
   .CONST $cbops.univ_mix_op.common.PRIMARY_AND_SECONDARY_CHANNEL_ACTIVE (0x000003);

   .CONST $cbops.univ_mix_op.common.DONT_MIX_PRIMARY_AND_SECONDARY_OUTPUTS (0x000000);
   .CONST $cbops.univ_mix_op.common.MIX_PRIMARY_AND_SECONDARY_OUTPUTS (0x000001);

   .CONST $cbops.univ_mix_op.UNITY_PHASE 0.125;
   .CONST $cbops.univ_mix_op.UNITY_PHASE_SHIFT_NORMALIZE 3;
   .CONST $cbops.univ_mix_op.PHASE_FRACTIONAL_PART_MASK (0x0fffff);
.linefile 110 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_s_to_m_op.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_s_to_m_op.h"
   .CONST $cbops.s_to_m_op.INPUT_LEFT_INDEX_FIELD 0;
   .CONST $cbops.s_to_m_op.INPUT_RIGHT_INDEX_FIELD 1;
   .CONST $cbops.s_to_m_op.OUTPUT_MONO_INDEX_FIELD 2;
   .CONST $cbops.s_to_m_op.STRUC_SIZE 3;
.linefile 113 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_cross_mix.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_cross_mix.h"
   .CONST $cbops.cross_mix.INPUT1_START_INDEX_FIELD 0;
   .CONST $cbops.cross_mix.INPUT2_START_INDEX_FIELD 1;
   .CONST $cbops.cross_mix.OUTPUT1_START_INDEX_FIELD 2;
   .CONST $cbops.cross_mix.OUTPUT2_START_INDEX_FIELD 3;
   .CONST $cbops.cross_mix.COEFF11_FIELD 4;
   .CONST $cbops.cross_mix.COEFF12_FIELD 5;
   .CONST $cbops.cross_mix.COEFF21_FIELD 6;
   .CONST $cbops.cross_mix.COEFF22_FIELD 7;

   .CONST $cbops.cross_mix.STRUC_SIZE 8;
.linefile 116 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_user_filter.h" 1
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_user_filter.h"
   .CONST $cbops.user_filter.FUNCTION_PTR_PTR ($cbops.shift.STRUC_SIZE);
   .CONST $cbops.user_filter.STRUC_SIZE ($cbops.shift.STRUC_SIZE + 1);
.linefile 119 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/iir_resample/iir_resample_header.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/iir_resample/iir_resample_header.h"
   .CONST $cbops.mono.iir_resample.INPUT_1_START_INDEX_FIELD 0;
   .CONST $cbops.mono.iir_resample.OUTPUT_1_START_INDEX_FIELD 1;
   .CONST $cbops.mono.iir_resample.FILTER_DEFINITION_PTR_FIELD 2;
   .CONST $cbops.mono.iir_resample.INPUT_SCALE_FIELD 3;
   .CONST $cbops.mono.iir_resample.OUTPUT_SCALE_FIELD 4;
   .CONST $cbops.mono.iir_resample.SAMPLE_COUNT_FIELD 5;
   .CONST $cbops.mono.iir_resample.IIR_HISTORY_BUF_PTR_FIELD 6;
   .CONST $cbops.mono.iir_resample.FIR_HISTORY_BUF_PTR_FIELD 7;
   .CONST $cbops.mono.iir_resample.RESET_FLAG_FIELD 8;
   .CONST $cbops.mono.iir_resample.STRUC_SIZE 9;

   .CONST $cbops.stereo.iir_resample.INPUT_2_START_INDEX_FIELD 0;
   .CONST $cbops.stereo.iir_resample.OUTPUT_2_START_INDEX_FIELD 1;
   .CONST $cbops.stereo.iir_resample.INPUT_1_START_INDEX_FIELD 2;
   .CONST $cbops.stereo.iir_resample.OUTPUT_1_START_INDEX_FIELD 3;
   .CONST $cbops.stereo.iir_resample.FILTER_DEFINITION_PTR_FIELD 4;
   .CONST $cbops.stereo.iir_resample.INPUT_SCALE_FIELD 5;
   .CONST $cbops.stereo.iir_resample.OUTPUT_SCALE_FIELD 6;
   .CONST $cbops.stereo.iir_resample.CH1_SAMPLE_COUNT_FIELD 7;
   .CONST $cbops.stereo.iir_resample.CH1_IIR_HISTORY_BUF_PTR_FIELD 8;
   .CONST $cbops.stereo.iir_resample.CH1_FIR_HISTORY_BUF_PTR_FIELD 9;
   .CONST $cbops.stereo.iir_resample.CH2_SAMPLE_COUNT_FIELD 10;
   .CONST $cbops.stereo.iir_resample.CH2_IIR_HISTORY_BUF_PTR_FIELD 11;
   .CONST $cbops.stereo.iir_resample.CH2_FIR_HISTORY_BUF_PTR_FIELD 12;
   .CONST $cbops.stereo.iir_resample.RESET_FLAG_FIELD 13;
   .CONST $cbops.stereo.iir_resample.STRUC_SIZE 14;

   .CONST $cbops.iir_resample_complete.STRUC_SIZE 0;



   .CONST $cbops.frame.resample.CONVERSION_OBJECT_PTR_FIELD 0;
   .CONST $cbops.frame.resample.INPUT_PTR_FIELD 1;
   .CONST $cbops.frame.resample.INPUT_LENGTH_FIELD 2;
   .CONST $cbops.frame.resample.OUTPUT_PTR_FIELD 3;
   .CONST $cbops.frame.resample.OUTPUT_LENGTH_FIELD 4;
   .CONST $cbops.frame.resample.NUM_SAMPLES_FIELD 5;
   .CONST $cbops.frame.resample.SAMPLE_COUNT_FIELD 6;
   .CONST $cbops.frame.resample.IIR_HISTORY_BUF_PTR_FIELD 7;
   .CONST $cbops.frame.resample.FIR_HISTORY_BUF_PTR_FIELD 8;
   .CONST $cbops.frame.resample.DM1_OBJECT_SIZE_FIELD 9;


   .CONST $cbops.IIR_RESAMPLE_IIR_BUFFER_SIZE 9;
   .CONST $cbops.IIR_DOWNSAMPLE_FIR_BUFFER_SIZE 10;
   .CONST $cbops.IIR_UPSAMPLE_FIR_BUFFER_SIZE 7;
.linefile 121 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/iir_resamplev2/iir_resamplev2_header.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/iir_resamplev2/iir_resamplev2_header.h"
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



   .CONST $cbops.frame.resamplev2.INPUT_PTR_FIELD 0;
   .CONST $cbops.frame.resamplev2.INPUT_LENGTH_FIELD 1;
   .CONST $cbops.frame.resamplev2.OUTPUT_PTR_FIELD 2;
   .CONST $cbops.frame.resamplev2.OUTPUT_LENGTH_FIELD 3;
   .CONST $cbops.frame.resamplev2.NUM_SAMPLES_FIELD 4;

   .CONST $cbops.frame.resamplev2.FILTER_DEFINITION_PTR_FIELD 5;
   .CONST $cbops.frame.resamplev2.INPUT_SCALE_FIELD 6;
   .CONST $cbops.frame.resamplev2.OUTPUT_SCALE_FIELD 7;

   .CONST $cbops.frame.resamplev2.INTERMEDIATE_CBUF_PTR_FIELD 8;
   .CONST $cbops.frame.resamplev2.INTERMEDIATE_CBUF_LEN_FIELD 9;

   .CONST $cbops.frame.resamplev2.PARTIAL1_FIELD 10;
   .CONST $cbops.frame.resamplev2.SAMPLE_COUNT1_FIELD 11;
   .CONST $cbops.frame.resamplev2.FIR_HISTORY_BUF1_PTR_FIELD 12;
   .CONST $cbops.frame.resamplev2.IIR_HISTORY_BUF1_PTR_FIELD 13;

   .CONST $cbops.frame.resamplev2.PARTIAL2_FIELD 14;
   .CONST $cbops.frame.resamplev2.SAMPLE_COUNT2_FIELD 15;
   .CONST $cbops.frame.resamplev2.FIR_HISTORY_BUF2_PTR_FIELD 16;
   .CONST $cbops.frame.resamplev2.IIR_HISTORY_BUF2_PTR_FIELD 17;

   .CONST $cbops.frame.resamplev2.RESET_FLAG_FIELD 18;
   .CONST $cbops.frame.resamplev2.STRUC_SIZE 19;

   .CONST $cbops.frame.resamplev2.OBJECT_SIZE $cbops.frame.resamplev2.STRUC_SIZE + 2*$IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE;

   .CONST $cbops.frame.resamplev2.OBJECT_SIZE_SNGL_STAGE $cbops.frame.resamplev2.STRUC_SIZE + $IIR_RESAMPLEV2_APPENDED_BUFFER_SIZE;
.linefile 123 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2


.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_fixed_amount.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_fixed_amount.h"
   .CONST $cbops.fixed_amount.AMOUNT_FIELD 0;
   .CONST $cbops.fixed_amount.STRUC_SIZE 1;

   .CONST $cbops.fixed_amount.NO_AMOUNT -1;
.linefile 126 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_signal_detect.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_signal_detect.h"
    .const $cbops.signal_detect_op.COEFS_PTR 0;
    .const $cbops.signal_detect_op.NUM_CHANNELS 1;
    .const $cbops.signal_detect_op.FIRST_CHANNEL_INDEX 2;

    .const $cbops.signal_detect_op.STRUC_SIZE_MONO 3;
    .const $cbops.signal_detect_op.STRUC_SIZE_STEREO 4;
    .const $cbops.signal_detect_op.STRUC_SIZE_3_CHANNEL 5;




    .const $cbops.signal_detect_op_coef.LINEAR_THRESHOLD_VALUE 0;
    .const $cbops.signal_detect_op_coef.NO_SIGNAL_TRIGGER_TIME 1;
    .const $cbops.signal_detect_op_coef.CURRENT_MAX_VALUE 2;
    .const $cbops.signal_detect_op_coef.SECOND_TIMER 3;
    .const $cbops.signal_detect_op_coef.SIGNAL_STATUS 4;
    .const $cbops.signal_detect_op_coef.SIGNAL_STATUS_MSG_ID 5;

    .const $cbops.signal_detect_op_coef.STRUC_SIZE 6;
.linefile 128 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_stereo_soft_mute.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_stereo_soft_mute.h"
    .const $cbops.stereo_soft_mute_op.STRUC_SIZE 6;

    .const $cbops.stereo_soft_mute_op.INPUT_LEFT_START_INDEX_FIELD 0;
    .const $cbops.stereo_soft_mute_op.INPUT_RIGHT_START_INDEX_FIELD 1;
    .const $cbops.stereo_soft_mute_op.OUTPUT_LEFT_START_INDEX_FIELD 2;
    .const $cbops.stereo_soft_mute_op.OUTPUT_RIGHT_START_INDEX_FIELD 3;
    .const $cbops.stereo_soft_mute_op.MUTE_DIRECTION 4;
    .const $cbops.stereo_soft_mute_op.MUTE_INDEX 5;
.linefile 129 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_soft_mute.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_soft_mute.h"
    .const $cbops.soft_mute_op.STRUC_SIZE_MONO 5;
    .const $cbops.soft_mute_op.STRUC_SIZE_STEREO 7;

    .const $cbops.soft_mute_op.MUTE_DIRECTION 0;
    .const $cbops.soft_mute_op.MUTE_INDEX 1;
    .const $cbops.soft_mute_op.NUM_CHANNELS 2;
    .const $cbops.soft_mute_op.INPUT_1_START_INDEX_FIELD 3;
    .const $cbops.soft_mute_op.OUTPUT_1_START_INDEX_FIELD 4;
    .const $cbops.soft_mute_op.INPUT_2_START_INDEX_FIELD 5;
    .const $cbops.soft_mute_op.OUTPUT_2_START_INDEX_FIELD 6;
.linefile 130 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_switch.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_switch.h"
    .CONST $cbops.switch_op.SWITCH_ADDR_FIELD 0;
    .CONST $cbops.switch_op.ALT_NEXT_FIELD 1;
    .CONST $cbops.switch_op.SWITCH_MASK_FIELD 2;
    .CONST $cbops.switch_op.INVERT_CONTROL_FIELD 3;
    .CONST $cbops.switch_op.STRUC_SIZE 4;

    .CONST $cbops.switch_op.OFF 0;
    .CONST $cbops.switch_op.ON 1;

    .CONST $cbops.switch_op.INVERT_CONTROL 1;
.linefile 131 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_delay.h" 1
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/operators/cbops_delay.h"
    .const $cbops.delay.INPUT_INDEX 0;
    .const $cbops.delay.OUTPUT_INDEX 1;
    .const $cbops.delay.DBUFF_ADDR_FIELD 2;
    .const $cbops.delay.DBUFF_SIZE_FIELD 3;
    .const $cbops.delay.DELAY_FIELD 4;

    .const $cbops.delay.STRUC_SIZE 5;
.linefile 132 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops.h" 2
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cbops_library.h" 2
.linefile 10 "sr_adjustment_gaming.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/codec_library.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/codec_library.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/codec_library.h" 2






   .CONST $codec.NORMAL_DECODE 0;
   .CONST $codec.NO_OUTPUT_DECODE 1;
   .CONST $codec.GOBBLE_DECODE 2;

   .CONST $codec.SUCCESS 0;
   .CONST $codec.NOT_ENOUGH_INPUT_DATA 1;
   .CONST $codec.NOT_ENOUGH_OUTPUT_SPACE 2;
   .CONST $codec.ERROR 3;
   .CONST $codec.EOF 4;
   .CONST $codec.FRAME_CORRUPT 5;

   .CONST $codec.ENCODER_OUT_BUFFER_FIELD 0;
   .CONST $codec.ENCODER_IN_LEFT_BUFFER_FIELD 1;
   .CONST $codec.ENCODER_IN_RIGHT_BUFFER_FIELD 2;
   .CONST $codec.ENCODER_MODE_FIELD 3;
   .CONST $codec.ENCODER_DATA_OBJECT_FIELD 4;
   .CONST $codec.ENCODER_STRUC_SIZE 5;

   .CONST $codec.DECODER_IN_BUFFER_FIELD 0;
   .CONST $codec.DECODER_OUT_LEFT_BUFFER_FIELD 1;
   .CONST $codec.DECODER_OUT_RIGHT_BUFFER_FIELD 2;
   .CONST $codec.DECODER_MODE_FIELD 3;
   .CONST $codec.DECODER_NUM_OUTPUT_SAMPLES_FIELD 4;
   .CONST $codec.DECODER_DATA_OBJECT_FIELD 5;
   .CONST $codec.TWS_CALLBACK_FIELD 6;
   .CONST $codec.DECODER_STRUC_SIZE 7;

   .CONST $codec.DECRYPTER_IN_BUFFER_FIELD 0;
   .CONST $codec.DECRYPTER_OUT_BUFFER_FIELD 1;
   .CONST $codec.DECRYPTER_EXTRA_STRUC_PTR_FIELD 2;
   .CONST $codec.DECRYPTER_STRUC_SIZE 3;

   .CONST $codec.STREAM_CAN_IDLE 0;
   .CONST $codec.STREAM_DONT_IDLE 1;


   .CONST $codec.FRAME_DECODE 0;
   .CONST $codec.INIT_DECODER 1;
   .CONST $codec.RESET_DECODER 2;
   .CONST $codec.SILENCE_DECODER 3;
   .CONST $codec.SUSPEND_DECODER 4;
   .CONST $codec.RESUME_DECODER 5;
   .CONST $codec.STORE_BOUNDARY_SNAPSHOT 6;
   .CONST $codec.RESTORE_BOUNDARY_SNAPSHOT 7;
   .CONST $codec.FAST_SKIP 8;
   .CONST $codec.SET_SKIP_FUNCTION 9;
   .CONST $codec.SET_AVERAGE_BITRATE 10;
   .CONST $codec.SET_FILE_TYPE 11;
   .CONST $codec.DECRYPTER_SET_DECODER 12;
   .CONST $codec.DECRYPTER_SET_PARAMETERS 13;




   .CONST $codec.stream_encode.ADDR_FIELD 0;
   .CONST $codec.stream_encode.RESET_ADDR_FIELD 1;
   .CONST $codec.stream_encode.ENCODER_STRUC_FIELD $codec.stream_encode.RESET_ADDR_FIELD + 1;

   .CONST $codec.stream_encode.STATE_FIELD $codec.stream_encode.ENCODER_STRUC_FIELD + $codec.ENCODER_STRUC_SIZE;
   .CONST $codec.stream_encode.MEDIA_HDR_ADDR_FIELD $codec.stream_encode.STATE_FIELD + 1;
   .CONST $codec.stream_encode.STRUC_SIZE $codec.stream_encode.MEDIA_HDR_ADDR_FIELD + 1;


   .CONST $codec.stream_encode.OUT_BUFFER_FIELD $codec.stream_encode.ENCODER_STRUC_FIELD + $codec.ENCODER_OUT_BUFFER_FIELD;
   .CONST $codec.stream_encode.IN_LEFT_BUFFER_FIELD $codec.stream_encode.ENCODER_STRUC_FIELD + $codec.ENCODER_IN_LEFT_BUFFER_FIELD;
   .CONST $codec.stream_encode.IN_RIGHT_BUFFER_FIELD $codec.stream_encode.ENCODER_STRUC_FIELD + $codec.ENCODER_IN_RIGHT_BUFFER_FIELD;
   .CONST $codec.stream_encode.MODE_FIELD $codec.stream_encode.ENCODER_STRUC_FIELD + $codec.ENCODER_MODE_FIELD;






   .CONST $codec.SBC_RTP_AND_PAYLOAD_HEADER_SIZE 13;
   .CONST $codec.MP3_RTP_AND_PAYLOAD_HEADER_SIZE 16;
   .CONST $codec.APTX_RTP_AND_PAYLOAD_HEADER_SIZE 0;


   .CONST $codec.media_header.WRITE_HDR_FIELD 0;
   .CONST $codec.media_header.RTP_SEQUENCE_NUM_FIELD 1;
   .CONST $codec.media_header.RTP_TIMESTAMP_MS_FIELD 2;
   .CONST $codec.media_header.RTP_TIMESTAMP_LS_FIELD 3;
   .CONST $codec.media_header.FRAME_COUNT_FIELD 4;
   .CONST $codec.media_header.SAMPLES_PER_FRAME 5;
   .CONST $codec.media_header.PUT_BITS_ADDR_FIELD 6;
   .CONST $codec.media_header.GET_ENCODED_FRAME_INFO 7;
   .CONST $codec.media_header.NUM_FRAMES_FIELD 8;
   .CONST $codec.media_header.L2CAP_ATU_SIZE_FIELD 9;
   .CONST $codec.media_header.SHUNT_FRAME_BYTE_COUNT_FIELD 10;
   .CONST $codec.media_header.RTP_AND_PAYLOAD_HEADER_SIZE_FIELD 11;
   .CONST $codec.media_header.FASTSTREAM_ENABLED_FIELD 12;
   .CONST $codec.media_header.MEDIA_HDR_STRUC_SIZE $codec.media_header.FASTSTREAM_ENABLED_FIELD + 1;

   .CONST $codec.stream_encode.STATE_STOPPED 0;
   .CONST $codec.stream_encode.STATE_STREAMING 1;
   .CONST $codec.stream_encode.STATE_MASK 1;

   .CONST $codec.stream_decode.ADDR_FIELD 0;
   .CONST $codec.stream_decode.RESET_ADDR_FIELD 1;
   .CONST $codec.stream_decode.SILENCE_ADDR_FIELD 2;
   .CONST $codec.stream_decode.DECODER_STRUC_FIELD $codec.stream_decode.SILENCE_ADDR_FIELD + 1;

   .CONST $codec.stream_decode.COMFORT_NOISE_GAIN_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 0;
   .CONST $codec.stream_decode.GOOD_WORKING_BUFLEVEL_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 1;
   .CONST $codec.stream_decode.POORLINK_DETECT_BUFLEVEL_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 2;
   .CONST $codec.stream_decode.POORLINK_PERIOD_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 3;
   .CONST $codec.stream_decode.PLAYING_ZERO_DATARATE_PERIOD_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 4;
   .CONST $codec.stream_decode.BUFFERING_ZERO_DATARATE_PERIOD_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 5;
   .CONST $codec.stream_decode.POORLINK_DETECT_TABLE_ADDR_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 6;
   .CONST $codec.stream_decode.POORLINK_DETECT_TABLE_SIZE_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 7;
   .CONST $codec.stream_decode.WARP_RATE_HIGH_COEF_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 8;
   .CONST $codec.stream_decode.WARP_RATE_LOW_COEF_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 9;
   .CONST $codec.stream_decode.WARP_RATE_TRANSITION_LEVEL_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 10;
   .CONST $codec.stream_decode.POORLINK_DETECT_TABLE_OFFSET_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 11;
   .CONST $codec.stream_decode.RAND_LAST_VAL_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 12;
   .CONST $codec.stream_decode.STATE_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 13;
   .CONST $codec.stream_decode.POORLINK_ENDTIME_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 14;
   .CONST $codec.stream_decode.ZERO_DATARATE_ENDTIME_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 15;
   .CONST $codec.stream_decode.PLAYING_STARTTIME_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 16;
   .CONST $codec.stream_decode.PREV_WRITE_PTR_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 17;
   .CONST $codec.stream_decode.FAST_AVERAGE_BUFLEVEL_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 18;
   .CONST $codec.stream_decode.SLOW_AVERAGE_BUFLEVEL_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 19;
   .CONST $codec.stream_decode.SLOW_AVERAGE_SAMPLE_TIME_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 20;
   .CONST $codec.stream_decode.WARP_TARGET_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_STRUC_SIZE + 21;
   .CONST $codec.stream_decode.STRUC_SIZE $codec.stream_decode.WARP_TARGET_FIELD + 1;


   .CONST $codec.stream_decode.IN_BUFFER_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_IN_BUFFER_FIELD;
   .CONST $codec.stream_decode.OUT_LEFT_BUFFER_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_OUT_LEFT_BUFFER_FIELD;
   .CONST $codec.stream_decode.OUT_RIGHT_BUFFER_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_OUT_RIGHT_BUFFER_FIELD;
   .CONST $codec.stream_decode.MODE_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_MODE_FIELD;
   .CONST $codec.stream_decode.NUM_OUTPUT_SAMPLES_FIELD $codec.stream_decode.DECODER_STRUC_FIELD + $codec.DECODER_NUM_OUTPUT_SAMPLES_FIELD;



   .CONST $codec.stream_decode.STATE_BUFFERING 0;
   .CONST $codec.stream_decode.STATE_PLAYING 1;
   .CONST $codec.stream_decode.STATE_MASK 1;

   .CONST $codec.stream_decode_sync.CONDITION_READ_WALL_CLOCK 2;
   .CONST $codec.stream_decode_sync.CONDITION_DECODE_FRAME 4;
   .CONST $codec.stream_decode_sync.CONDITION_INSERT_SAMPLES 8;

   .CONST $codec.stream_decode.CONDITION_POORLINK 2;
   .CONST $codec.stream_decode.CONDITION_DETECT_POORLINK_ENABLE 4;
   .CONST $codec.stream_decode.CONDITION_ZERO_DATARATE 8;
   .CONST $codec.stream_decode.CONDITION_STOPPING 16;

   .CONST $codec.stream_decode.FAST_AVERAGE_SHIFT_CONST -6;
   .CONST $codec.stream_decode.SLOW_AVERAGE_SHIFT_CONST -2;
   .CONST $codec.stream_decode.SLOW_AVERAGE_SAMPLE_PERIOD 50000;
.linefile 177 "C:/ADK3.5/kalimba/lib_sets/sdk/include/codec_library.h"
   .CONST $codec.stream_relay.GET_FRAME_INFO_ADDR_FIELD 0;
   .CONST $codec.stream_relay.IN_BUFFER_FIELD 1;
   .CONST $codec.stream_relay.LOCAL_RELAY_BUFFER_FIELD 2;
   .CONST $codec.stream_relay.REMOTE_RELAY_BUFFER_FIELD 3;
   .CONST $codec.stream_relay.BUFFER_DELAY_IN_US_FIELD 4;
   .CONST $codec.stream_relay.WARP_RATE_COEF_FIELD 5;
   .CONST $codec.stream_relay.NUM_AUDIO_SAMPLES_CONSUMED_PNTR_FIELD 6;
   .CONST $codec.stream_relay.WALL_CLOCK_STRUC_PNTR_FIELD 7;
   .CONST $codec.stream_relay.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD 8;
   .CONST $codec.stream_relay.PREVIOUS_AUDIO_FRAME_LENGTH_FIELD 9;
   .CONST $codec.stream_relay.SLOW_AVERAGE_BUFLEVEL_FIELD 10;
   .CONST $codec.stream_relay.SLOW_AVERAGE_SAMPLE_TIME_FIELD 11;
   .CONST $codec.stream_relay.STATE_FIELD 12;
   .CONST $codec.stream_relay.TIME_TO_PLAY_FIELD 13;
   .CONST $codec.stream_relay.NUM_AUDIO_SAMPLES_IN_BUFFER_FIELD 14;
   .CONST $codec.stream_relay.GOOD_WORKING_BUFLEVEL_FIELD 15;
   .CONST $codec.stream_relay.STRUC_SIZE 16;

   .CONST $codec.stream_relay.SLOW_AVERAGE_SAMPLE_PERIOD 50000;
   .CONST $codec.stream_relay.SLOW_AVERAGE_SHIFT_CONST -2;

   .CONST $codec.stream_relay.STATE_BUFFERING 0;
   .CONST $codec.stream_relay.STATE_PLAYING 1;



   .CONST $codec.stream_decode_sync.ADDR_FIELD 0;
   .CONST $codec.stream_decode_sync.RESET_ADDR_FIELD 1;
   .CONST $codec.stream_decode_sync.SILENCE_ADDR_FIELD 2;
   .CONST $codec.stream_decode_sync.GET_FRAME_INFO_ADDR_FIELD 3;
   .CONST $codec.stream_decode_sync.LEFT_DAC_PORT_FIELD 4;
   .CONST $codec.stream_decode_sync.RIGHT_DAC_PORT_FIELD 5;
   .CONST $codec.stream_decode_sync.IN_BUFFER_FIELD 6;
   .CONST $codec.stream_decode_sync.OUT_LEFT_BUFFER_FIELD 7;
   .CONST $codec.stream_decode_sync.OUT_RIGHT_BUFFER_FIELD 8;
   .CONST $codec.stream_decode_sync.MODE_FIELD 9;
   .CONST $codec.stream_decode_sync.NUM_OUTPUT_SAMPLES_FIELD 10;
   .CONST $codec.stream_decode_sync.COMFORT_NOISE_GAIN_FIELD 11;
   .CONST $codec.stream_decode_sync.DELAY_TO_WARP_COEF_FIELD 12;
   .CONST $codec.stream_decode_sync.MAX_PLAY_TIME_OFFSET_IN_US_FIELD 13;
   .CONST $codec.stream_decode_sync.GENERATE_SILENCE_THRESHOLD_FIELD 14;
   .CONST $codec.stream_decode_sync.AMOUNT_OF_SILENCE_TO_GENERATE_FIELD 15;
   .CONST $codec.stream_decode_sync.CURRENT_MODE_FIELD 16;
   .CONST $codec.stream_decode_sync.DECODER_MODE_FIELD 17;
   .CONST $codec.stream_decode_sync.FRAME_PLAY_TIME_FIELD 18;
   .CONST $codec.stream_decode_sync.NUM_MICRO_SECS_PER_1024_SAMPLES_FIELD 19;
   .CONST $codec.stream_decode_sync.NUM_SAMPLES_PER_US_FIELD 20;
   .CONST $codec.stream_decode_sync.PADDING_BYTE_FIELD 21;
   .CONST $codec.stream_decode_sync.RAND_LAST_VAL_FIELD 22;
   .CONST $codec.stream_decode_sync.REQUESTED_WARP_FIELD 23;
   .CONST $codec.stream_decode_sync.STREAMING_FIELD 24;
   .CONST $codec.stream_decode_sync.AUDIO_SAMPLES_CONSUMED_FIELD 25;
   .CONST $codec.stream_decode_sync.WALL_CLOCK_STRUC_FIELD 26;
   .CONST $codec.stream_decode_sync.STRUC_SIZE ($codec.stream_decode_sync.WALL_CLOCK_STRUC_FIELD + $wall_clock.STRUC_SIZE);

   .CONST $codec.stream_decode_sync.STREAMING_STOPPED 0;
   .CONST $codec.stream_decode_sync.STREAMING_PLAYING 1;



   .CONST $codec.av_encode.ADDR_FIELD 0;
   .CONST $codec.av_encode.RESET_ADDR_FIELD $codec.av_encode.ADDR_FIELD + 1;

   .CONST $codec.av_encode.ENCODER_STRUC_FIELD $codec.av_encode.RESET_ADDR_FIELD + 1;
   .CONST $codec.av_encode.OUT_BUFFER_FIELD $codec.av_encode.ENCODER_STRUC_FIELD;
   .CONST $codec.av_encode.IN_LEFT_BUFFER_FIELD $codec.av_encode.OUT_BUFFER_FIELD + 1;
   .CONST $codec.av_encode.IN_RIGHT_BUFFER_FIELD $codec.av_encode.IN_LEFT_BUFFER_FIELD + 1;
   .CONST $codec.av_encode.MODE_FIELD $codec.av_encode.IN_RIGHT_BUFFER_FIELD + 1;

   .CONST $codec.av_encode.ENCODER_DATA_OBJECT_FIELD $codec.av_encode.MODE_FIELD + 1;
   .CONST $codec.av_encode.BUFFERING_THRESHOLD_FIELD $codec.av_encode.ENCODER_DATA_OBJECT_FIELD + 1;
   .CONST $codec.av_encode.STALL_COUNTER_FIELD $codec.av_encode.BUFFERING_THRESHOLD_FIELD + 1;

   .CONST $codec.av_encode.STRUC_SIZE $codec.av_encode.STALL_COUNTER_FIELD + 1;


   .CONST $codec.av_decode.ADDR_FIELD 0;
   .CONST $codec.av_decode.RESET_ADDR_FIELD $codec.av_decode.ADDR_FIELD + 1;
   .CONST $codec.av_decode.SILENCE_ADDR_FIELD $codec.av_decode.RESET_ADDR_FIELD + 1;

   .CONST $codec.av_decode.DECODER_STRUC_FIELD $codec.av_decode.SILENCE_ADDR_FIELD + 1;
   .CONST $codec.av_decode.IN_BUFFER_FIELD $codec.av_decode.DECODER_STRUC_FIELD;
   .CONST $codec.av_decode.OUT_LEFT_BUFFER_FIELD $codec.av_decode.IN_BUFFER_FIELD + 1;
   .CONST $codec.av_decode.OUT_RIGHT_BUFFER_FIELD $codec.av_decode.OUT_LEFT_BUFFER_FIELD + 1;
   .CONST $codec.av_decode.MODE_FIELD $codec.av_decode.OUT_RIGHT_BUFFER_FIELD + 1;
   .CONST $codec.av_decode.DECODER_NUM_OUTPUT_SAMPLES_FIELD $codec.av_decode.MODE_FIELD + 1;

   .CONST $codec.av_decode.DECODER_DATA_OBJECT_FIELD $codec.av_decode.DECODER_NUM_OUTPUT_SAMPLES_FIELD + 1;
   .CONST $codec.av_decode.TWS_CALLBACK_FIELD $codec.av_decode.DECODER_DATA_OBJECT_FIELD + 1;
   .CONST $codec.av_decode.DECODE_TO_STALL_THRESHOLD $codec.av_decode.TWS_CALLBACK_FIELD + 1;
   .CONST $codec.av_decode.STALL_BUFFER_LEVEL_FIELD $codec.av_decode.DECODE_TO_STALL_THRESHOLD + 1;
   .CONST $codec.av_decode.NORMAL_BUFFER_LEVEL_FIELD $codec.av_decode.STALL_BUFFER_LEVEL_FIELD + 1;
   .CONST $codec.av_decode.CODEC_PURGE_ENABLE_FIELD $codec.av_decode.NORMAL_BUFFER_LEVEL_FIELD + 1;
   .CONST $codec.av_decode.MASTER_RESET_FUNC_FIELD $codec.av_decode.CODEC_PURGE_ENABLE_FIELD + 1;

   .CONST $codec.av_decode.CODEC_PREV_WADDR_FIELD $codec.av_decode.MASTER_RESET_FUNC_FIELD + 1;
   .CONST $codec.av_decode.PAUSE_TIMER_FIELD $codec.av_decode.CODEC_PREV_WADDR_FIELD + 1;
   .CONST $codec.av_decode.CURRENT_RUNNING_MODE_FIELD $codec.av_decode.PAUSE_TIMER_FIELD + 1;
   .CONST $codec.av_decode.CAN_SWITCH_FIELD $codec.av_decode.CURRENT_RUNNING_MODE_FIELD + 1;
   .CONST $codec.av_decode.PREV_TIME_FIELD $codec.av_decode.CAN_SWITCH_FIELD + 1;

   .CONST $codec.av_decode.STRUC_SIZE $codec.av_decode.PREV_TIME_FIELD + 1;

   .CONST $codec.av_decode.PAUSE_TO_CLEAR_THRESHOLD 150;
   .CONST $codec.av_decode.STALL_TO_DECODE_THRESHOLD 70;
   .CONST $codec.av_encode.STALL_THRESHOLD 10;

   .CONST $codec.pre_post_proc.PRE_PROC_FUNC_ADDR_FIELD 0;
   .CONST $codec.pre_post_proc.PRE_PROC_FUNC_DATA1_FIELD 1;
   .CONST $codec.pre_post_proc.PRE_PROC_FUNC_DATA2_FIELD 2;
   .CONST $codec.pre_post_proc.POST_PROC_FUNC_ADDR_FIELD 3;
   .CONST $codec.pre_post_proc.POST_PROC_FUNC_DATA1_FIELD 4;
   .CONST $codec.pre_post_proc.POST_PROC_FUNC_DATA2_FIELD 5;
   .CONST $codec.pre_post_proc.STRUC_SIZE 6;

   .CONST $codec.stream_encode.mux.NEXT_SINK_HANDLER_FIELD 0;
   .CONST $codec.stream_encode.mux.STATE_FIELD 1;
   .CONST $codec.stream_encode.mux.PREV_READ_PNTR_FIELD 2;
   .CONST $codec.stream_encode.mux.AMOUNT_LEFT_TO_DISCARD_FIELD 3;
   .CONST $codec.stream_encode.mux.TERMINAL_FIELD 4;
   .CONST $codec.stream_encode.mux.PORT_FIELD 5;
   .CONST $codec.stream_encode.mux.BYTE_ALIGNMENT_FIELD 6;
   .CONST $codec.stream_encode.mux.CBUFFER_STRUC_FIELD 7;
   .CONST $codec.stream_encode.mux.STRUC_SIZE $codec.stream_encode.mux.CBUFFER_STRUC_FIELD + $cbuffer.STRUC_SIZE;
.linefile 11 "sr_adjustment_gaming.asm" 2
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
.linefile 12 "sr_adjustment_gaming.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h" 1
.linefile 55 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_GO 0x7000;
.linefile 65 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_SBCDEC_CONVERT_TO_MONO 0x7010;
.linefile 76 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_SBCENC_SET_BITPOOL 0x7020;
.linefile 93 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_SBCENC_SET_PARAMS 0x7021;
.linefile 103 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_MP3DEC_CONVERT_TO_MONO 0x7030;
.linefile 113 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_AACDEC_CONVERT_TO_MONO 0x7040;
.linefile 124 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_AACDEC_SET_FILE_TYPE 0x7041;
.linefile 137 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_COOKDEC_SET_PARAMS 0x7050;
.linefile 147 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_COOKDEC_SAMPLE_RATE 0x7051;
.linefile 158 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_SOURCE_CLOCK_MISMATCH_RATE 0x7070;
.linefile 170 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_PULSE_LED 0x7100;
.linefile 183 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_DTMF_NEW_TONE_MESSAGE_ID 0x7150;
.linefile 198 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_CBOPS_SILENCE_CLIP_DETECT_INITIALISE_ID 0x7200;
.linefile 210 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_CBOPS_SILENCE_CLIP_DETECT_CLIP_DETECTED_ID 0x7201;
.linefile 221 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_CBOPS_SILENCE_CLIP_DETECT_SILENCE_DETECTED_ID 0x7202;
.linefile 232 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h"
.CONST $MESSAGE_GRAPHIX_DRIVER_FROM_VM_MSG_ID 0x7400;


.linefile 1 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h" 1
.linefile 52 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_KALIMBA_READY 0x8000;
.linefile 82 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_CONFIGURE_PORT 0x8001;
.linefile 98 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_DATA_CONSUMED 0x8002;
.linefile 114 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_DATA_PRODUCED 0x8003;
.linefile 130 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_WARP_DAC 0x8004;
.linefile 152 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_WARP_ADC 0x8005;
.linefile 167 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_PS_READ 0x8006;
.linefile 188 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $LONG_MESSAGE_PS_RESULT 0x8007;
.linefile 204 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_PS_FAIL 0x8008;
.linefile 226 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_FILE_ADDRESS 0x8009;
.linefile 295 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_RAND_REQ 0x800D;
.linefile 320 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $LONG_MESSAGE_RAND_RESULT 0x800E;
.linefile 336 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_RAND_FAIL 0x800F;
.linefile 357 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_WATCHDOG_SET 0x8010;
.linefile 413 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_GET_SCO_PARAMS 0x8014;
.linefile 440 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $LONG_MESSAGE_SCO_PARAMS_RESULT 0x8015;
.linefile 451 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_GET_SCO_PARAMS_FAILED 0x8016;
.linefile 463 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_SET_FRAME_LENGTH 0x8017;
.linefile 474 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_GET_BT_ADDRESS 0x8018;
.linefile 491 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_PORT_BT_ADDRESS 0x8019;
.linefile 503 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_FRAME_LENGTH_RESPONSE 0x801A;
.linefile 522 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_GET_WALL_CLOCK_TBTA 0x801B;
.linefile 542 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $LONG_MESSAGE_WALL_CLOCK_RESPONSE_TBTA 0x801C;
.linefile 556 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_WALL_CLOCK_FAILED_TBTA 0x801D;
.linefile 570 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_GET_NEXT_ACTIVITY_TIME 0x801E;
.linefile 587 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $LONG_MESSAGE_GET_NEXT_ACTIVITY_TIME_RESPONSE 0x801F;
.linefile 601 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_GET_NEXT_ACTIVITY_TIME_FAILED 0x8020;
.linefile 624 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_CHANGE_PIO_OWNERSHIP 0x8021;
.linefile 643 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_PIO_OWNERSHIP_RESPONSE 0x8022;


.CONST $MESSAGE_CONFIGURE_BITSERIALISER 0x8023;
.linefile 665 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_CHARGER_LIMIT_CURRENT_USE 0x8024;



.CONST $MESSAGE_CONFIGURE_QPWM 0x8025;


.CONST $MESSAGE_CONFIGURE_XIO 0x8026;
.linefile 699 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_REGISTER_COPIES_REQUEST 0x8027;
.linefile 737 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_REGISTER_COPIES_REPLY 0x8028;
.linefile 759 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_REGISTER_COPIES_ALERT 0x8029;
.linefile 768 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_BITSERIAL_BUS_SWITCH 0x802A;
.linefile 788 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_AUDIO_STREAM_RATE_EVENT 0x802B;
.linefile 804 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_SPDIF_CHNL_STS_EVENT 0x802C;
.linefile 819 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_AUDIO_CONFIGURE 0x802D;
.linefile 830 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_AUDIO_CONFIGURE_RESPONSE 0x802E;
.linefile 844 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_ACTIVATE_AUDIO 0x802F;
.linefile 855 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_ACTIVATE_AUDIO_RESPONSE 0x8030;
.linefile 869 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_SPDIF_BLOCK_START_EVENT 0x8031;





.CONST $MESSAGE_BATON_BASE 0x9000;
.CONST $MESSAGE_BATON_LIMIT 0x91FF;
.linefile 888 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_IMMEDIATE_PANIC 0xFFC0;
.linefile 906 "C:/ADK3.5/kalimba/external_includes/firmware/kalimba_messages.h"
.CONST $MESSAGE_PART_BASE 0xFFF0;
.linefile 236 "C:/ADK3.5/kalimba/external_includes/vm/kalimba_standard_messages.h" 2
.linefile 13 "sr_adjustment_gaming.asm" 2
.linefile 29 "sr_adjustment_gaming.asm"
.MODULE $M.sra_calcrate;
   .CODESEGMENT MUSIC_EXAMPLE_SRA_CALCRATE_PM;
   .DATASEGMENT DM;

  .VAR mode_funtion_table[] = &idle, &start, &addup;

   $sra_calcrate:


   push rLink;


      r0 = M[$decoder_codec_stream_struc + $codec.av_decode.CURRENT_RUNNING_MODE_FIELD];
      if Z jump $reset_sra;



   r0 = M[$sra_struct + $sra.RATECALC_MODE_FIELD];
   r0 = M[r0 + mode_funtion_table];
   jump r0;



idle:

   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD];

   if Z jump end;


   r0 = $sra.RATECALC_START_MODE;
   M[$sra_struct + $sra.RATECALC_MODE_FIELD] = r0;


start:

   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   call $cbuffer.get_read_address_and_size;


   r1 = M[$sra_struct + $sra.CODEC_CBUFFER_PREV_READ_ADDR_FIELD];
   r2 = M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD];
   call is_it_within_range;


   Null = r3;
   if Z jump end;



 M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD] = NULL;


 M[$sra_struct + $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD] = Null;


 r0 = $sra.RATECALC_ADD_MODE;
 M[$sra_struct + $sra.RATECALC_MODE_FIELD] = r0;
 jump end;




addup:


  r0 = M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD];
  call $cbuffer.get_write_address_and_size;
  r2 = r0 - M[$sra_struct + $sra.AUDIO_CBUFFER_PREV_WRITE_ADDR_FIELD];
  if NEG r2 = r2 + r1;

  r1 = r2 + M[$sra_struct + $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD];
  M[$sra_struct + $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD] = r1;


  r2 = M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD];
  if Z jump end;

  r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
  call $cbuffer.get_read_address_and_size;
  r1 = M[$sra_struct + $sra.CODEC_CBUFFER_PREV_READ_ADDR_FIELD];
  r2 = M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD];
  call is_it_within_range;
  Null = r3;

  if Z jump end;



  M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD] = Null;

  r0 = $sra.RATECALC_IDLE_MODE;
  M[$sra_struct + $sra.RATECALC_MODE_FIELD] = r0;


  r2 = M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD];
  r3 = 1;
  r1 = r2 - M[$sra_struct + $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD];
  if NEG r3 = -r3;
  r1 = r1*r3(int);
  r7 = M[$sra_struct + $sra.MAX_RATE_FIELD];
  r7 = r7 * 3 (int);
  r2 = r2 * r7(frac);
  r2 = r1 - r2;

  if POS jump idle;

  r1 = r1*r3(int);

  r0 = M[$sra_struct + $sra.HIST_INDEX_FIELD];
  M[r0 + ($sra_struct+$sra.HIST_BUFF_FIELD)] = r1;


  r0 = r0 + 1;
  r0 = r0 AND ($sra.BUFF_SIZE-1);
  M[$sra_struct + $sra.HIST_INDEX_FIELD] = r0;


  if NZ jump init_phase_passed;
  r2 = $sra.STEADY_SAVING_MODE;
  M[$sra_struct + $sra.SAVIN_STATE_FIELD] = r2;
  init_phase_passed:


  r1 = $sra.BUFF_SIZE;
  Null = M[$sra_struct + $sra.SAVIN_STATE_FIELD];
  if NZ r0 = r1;

  calc_final_rate:

  r10 = r0 - 1;
  r3 = 1.0;
  I0 = (&$sra_struct+$sra.HIST_BUFF_FIELD);
  r1 = 0, r2 = M[I0, 1];
  do acc_loop;
     r1 = r1 + r2, r2 = M[I0, 1];
  acc_loop:
  r1 = r1 + r2;


  if NEG r3 = -r3;
  r1 = r1 * r3 (frac);


  rMAC = 0;
  rMAC0 = r1;
  Div = rMAC / r0;
  r1 = DivResult;


  rMAC = r1 ASHIFT -1;
  r2 = M[$sra_struct + $sra.AUDIO_AMOUNT_EXPECTED_FIELD];
  Div = rMAC / r2;
  r1 = DivResult;

  r2 = r1 - M[$sra_struct + $sra.MAX_RATE_FIELD];
  if POS r1 = r1 - r2;

  r1 = r1 * r3 (frac);

  M[$sra_struct + $sra.RATE_BEFORE_FIX_FIELD] = r1;


  jump idle;

end:

 r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
 call $cbuffer.get_read_address_and_size;
 M[$sra_struct + $sra.CODEC_CBUFFER_PREV_READ_ADDR_FIELD] = r0;


 r0 = M[$sra_struct + $sra.AUDIO_CBUFFER_TO_TAG_FIELD];
 call $cbuffer.get_write_address_and_size;
 M[$sra_struct + $sra.AUDIO_CBUFFER_PREV_WRITE_ADDR_FIELD] = r0;

 exit:


   jump $pop_rLink_and_rts;



 is_it_within_range:
  r3 = 1;
  Null = r0 - r1;
  if NEG jump neg_part;
  pos_part:

   Null = r2 - r0;
   if POS r3 = 0;
   Null = r2 - r1;
   if NEG r3 = 0;
  rts;

 neg_part:
   Null = r2 - r1;
   if POS rts;
   Null = r2 - r0;
   if POS r3 = 0;

rts;
.ENDMODULE;
.linefile 242 "sr_adjustment_gaming.asm"
.MODULE $M.sra_tagtimes;
   .CODESEGMENT MUSIC_EXAMPLE_SRA_TAGTIMES_PM;
   .DATASEGMENT DM;

  .VAR mode_funtion_table[] = &idle, &counting;

   $sra_tagtimes:


   push rLink;


   r0 = M[$sra_struct + $sra.CODEC_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   r5 = r0;
   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   call $cbuffer.calc_amount_data;
   r5 = r5 + r0;


   r5 = r5 + M[$sra_struct + $sra.BUFFER_LEVEL_ACC_FIELD];
   M[$sra_struct + $sra.BUFFER_LEVEL_ACC_FIELD] = r5;


   r4 = M[$sra_struct + $sra.BUFFER_LEVEL_COUNTER_FIELD];
   r4 = r4 + 1;
   M[$sra_struct + $sra.BUFFER_LEVEL_COUNTER_FIELD] = r4;


   r1 = M[$sra_struct + $sra.TAG_DURATION_FIELD];
   r1 = r1 * 0.125(frac);
   Null = r4 - r1;

   if NEG jump no_update_on_buf_level;

   M[$sra_struct + $sra.BUFFER_LEVEL_COUNTER_FIELD] = Null;
   M[$sra_struct + $sra.BUFFER_LEVEL_ACC_FIELD] = Null;
   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   r0 = M[r0];
   r0 = r0 * r4 (int);
   rMAC = r5 ASHIFT -1;
   Div = rMAC / r0;
   r1 = DivResult;
   r4 = M[$sra_struct + $sra.AVERAGE_LEVEL_FIELD];
   M[$sra_struct +$sra.AVERAGE_LEVEL_FIELD] = r1;
   r4 = r1 - r4;
   r0 = M[$sra_struct + $sra.TARGET_LEVEL_FIELD];
   r2 = r1 - r0;
   r2 = r2 * (-0.05)(frac);
   r1 = r2 - 0.005;
   if POS r2 = r2 - r1;
   r1 = r2 + 0.0025;
   if NEG r2 = r2 - r1;
   r7 = 0.0005;
   r6 = M[$sra_struct + $sra.FIX_VALUE_FIELD];
   r0 = r2;
fix_rate:

   r1 = r6 + r7;
   NULL = r0 - r1;
   if POS r0 = r1;
   r1 = r6 - r7;
   NULL = r0 - r1;
   if NEG r0 = r1;

   M[$sra_struct + $sra.FIX_VALUE_FIELD] = r0;


set_final_rate:

   r0 = M[$sra_struct + $sra.RATE_BEFORE_FIX_FIELD];
   r0 = r0 + M[$sra_struct + $sra.FIX_VALUE_FIELD];

   r1 = r0 - M[$sra_struct + $sra.MAX_RATE_FIELD];
   if POS r0 = r0 - r1;
   r1 = r0 + M[$sra_struct + $sra.MAX_RATE_FIELD];
   if NEG r0 = r0 - r1;
   r1 = r0 + 0.015;
   if NEG r0 = r0 - r1;
   r6 = M[$sra_struct + $sra.SRA_RATE_FIELD];
   r1 = r6 + r7;
   NULL = r0 - r1;
   if POS r0 = r1;
   r1 = r6 - r7;
   NULL = r0 - r1;
   if NEG r0 = r1;
   M[$sra_struct + $sra.SRA_RATE_FIELD] = r0;

no_update_on_buf_level:

   r0 = M[$sra_struct + $sra.CODEC_PORT_FIELD];
   call $cbuffer.calc_amount_data;
   r3 = r0;


   r0 = M[$sra_struct+ $sra.NO_CODEC_DATA_COUNTER_FIELD];
   r0 = r0 + 1;
   Null = r3;
   if NZ r0 = 0;
   M[$sra_struct+ $sra.NO_CODEC_DATA_COUNTER_FIELD] = r0;


   Null = r0 - $sra.NO_ACTIVITY_PERIOD;
   if NEG jump no_reset_sra;
   M[$sra_struct + $sra.FIX_VALUE_FIELD] = Null;
   jump $reset_sra;

no_reset_sra:

   r0 = M[$sra_struct + $sra.ACTIVE_PERIOD_COUNTER_FIELD];
   r1 = $sra.ACTIVITY_PERIOD_BEFORE_START + 10;
   r0 = r0 + 1;
   Null = r0 - r1;
   if POS r0 = r1;
   M[$sra_struct + $sra.ACTIVE_PERIOD_COUNTER_FIELD] = r0;


   r0 = M[$sra_struct + $sra.MODE_FIELD];
   r0 = M[r0 + mode_funtion_table];
   jump r0;


 idle:

   r0 = M[$sra_struct + $sra.ACTIVE_PERIOD_COUNTER_FIELD];
   Null = r0 - $sra.ACTIVITY_PERIOD_BEFORE_START;
   if POS jump start;
   jump end;


start:



   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   call $cbuffer.get_write_address_and_size;
   M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD]= r0;


   r0 = $sra.COUNTING_MODE;
   M[$sra_struct + $sra.MODE_FIELD] = r0;
   M[$sra_struct + $sra.TAG_TIME_COUNTER_FIELD] = Null;


 counting:

   r0 = M[$sra_struct + $sra.TAG_TIME_COUNTER_FIELD];
   r0 = r0 + 1;
   M[$sra_struct + $sra.TAG_TIME_COUNTER_FIELD] = r0;

   r0 = r0 - 1;
   Null = r0 - M[$sra_struct + $sra.TAG_DURATION_FIELD];
   if NEG jump end;


   r0 = M[$sra_struct + $sra.RATECALC_MODE_FIELD];
   Null = r0 - $sra.RATECALC_ADD_MODE;
   if NZ jump $reset_sra;


   r0 = M[$sra_struct + $sra.CODEC_CBUFFER_TO_TAG_FIELD];
   call $cbuffer.get_write_address_and_size;
   M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD]= r0;


   jump idle;

end:

   jump $pop_rLink_and_rts;

  $reset_sra:
  M[$sra_struct + $sra.ACTIVE_PERIOD_COUNTER_FIELD] = Null;
  M[$sra_struct + $sra.RATECALC_MODE_FIELD] = Null;
  M[$sra_struct + $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD] = Null;
  M[$sra_struct + $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD] = Null;
  M[$sra_struct + $sra.MODE_FIELD] = Null;
  jump $pop_rLink_and_rts;

.ENDMODULE;
