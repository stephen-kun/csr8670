.linefile 1 "relay_conn.asm"
.linefile 1 "<command-line>"
.linefile 1 "relay_conn.asm"







.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stream_relay_library.h" 1
.linefile 9 "relay_conn.asm" 2
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
.linefile 10 "relay_conn.asm" 2
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
.linefile 11 "relay_conn.asm" 2
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
.linefile 12 "relay_conn.asm" 2
.linefile 1 "sr_adjustment.h" 1
.linefile 12 "sr_adjustment.h"
.linefile 1 "codec_decoder.h" 1
.linefile 11 "codec_decoder.h"
.linefile 1 "music_example.h" 1
.linefile 12 "music_example.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/music_manager_library_gen.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/music_manager_library_gen.h"
.CONST $MUSIC_MANAGER_SYSID 0xE008;


.CONST $M.MUSIC_MANAGER.CONFIG.VOLUME_LIMITER_BYPASS 0x001000;
.CONST $M.MUSIC_MANAGER.CONFIG.BASS_MANAGER_BYPASS 0x000800;
.CONST $M.MUSIC_MANAGER.CONFIG.SPKR_EQ_BYPASS 0x000400;
.CONST $M.MUSIC_MANAGER.CONFIG.EQFLAT 0x000200;
.CONST $M.MUSIC_MANAGER.CONFIG.USER_EQ_BYPASS 0x000100;
.CONST $M.MUSIC_MANAGER.CONFIG.BASS_BOOST_BYPASS 0x000080;
.CONST $M.MUSIC_MANAGER.CONFIG.SPATIAL_BYPASS 0x000040;
.CONST $M.MUSIC_MANAGER.CONFIG.COMPANDER_BYPASS 0x000020;
.CONST $M.MUSIC_MANAGER.CONFIG.DITHER_BYPASS 0x000010;
.CONST $M.MUSIC_MANAGER.CONFIG.USER_EQ_SELECT 0x000007;


.CONST $M.MUSIC_MANAGER.STATUS.CUR_MODE_OFFSET 0;
.CONST $M.MUSIC_MANAGER.STATUS.SYSCONTROL_OFFSET 1;
.CONST $M.MUSIC_MANAGER.STATUS.FUNC_MIPS_OFFSET 2;
.CONST $M.MUSIC_MANAGER.STATUS.DECODER_MIPS_OFFSET 3;
.CONST $M.MUSIC_MANAGER.STATUS.PEAK_PCMINL_OFFSET 4;
.CONST $M.MUSIC_MANAGER.STATUS.PEAK_PCMINR_OFFSET 5;
.CONST $M.MUSIC_MANAGER.STATUS.PEAK_PCMLFE_OFFSET 6;
.CONST $M.MUSIC_MANAGER.STATUS.PEAK_DACL_OFFSET 7;
.CONST $M.MUSIC_MANAGER.STATUS.PEAK_DACR_OFFSET 8;
.CONST $M.MUSIC_MANAGER.STATUS.PEAK_SUB_OFFSET 9;
.CONST $M.MUSIC_MANAGER.STATUS.VOL_SYS_OFFSET 10;
.CONST $M.MUSIC_MANAGER.STATUS.VOL_MAST_OFFSET 11;
.CONST $M.MUSIC_MANAGER.STATUS.TRIM_LEFT_OFFSET 12;
.CONST $M.MUSIC_MANAGER.STATUS.TRIM_RIGHT_OFFSET 13;
.CONST $M.MUSIC_MANAGER.STATUS.USER_EQ_BANK_OFFSET 14;
.CONST $M.MUSIC_MANAGER.STATUS.CONFIG_FLAG_OFFSET 15;
.CONST $M.MUSIC_MANAGER.STATUS.DELAY 16;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_TYPE_OFFSET 17;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_FS_OFFSET 18;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_CHANNEL_MODE 19;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT1 20;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT2 21;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT3 22;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT4 23;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT5 24;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT6 25;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT7 26;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT8 27;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STAT9 28;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STATA 29;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_STATB 30;
.CONST $M.MUSIC_MANAGER.STATUS.INTERFACE_TYPE 31;
.CONST $M.MUSIC_MANAGER.STATUS.INPUT_RATE 32;
.CONST $M.MUSIC_MANAGER.STATUS.OUTPUT_RATE 33;
.CONST $M.MUSIC_MANAGER.STATUS.CODEC_RATE 34;
.CONST $M.MUSIC_MANAGER.STATUS.BLOCK_SIZE 35;


.CONST $M.MUSIC_MANAGER.SYSMODE.STANDBY 0;
.CONST $M.MUSIC_MANAGER.SYSMODE.PASSTHRU 1;
.CONST $M.MUSIC_MANAGER.SYSMODE.FULLPROC 2;
.CONST $M.MUSIC_MANAGER.SYSMODE.MONO 3;
.CONST $M.MUSIC_MANAGER.SYSMODE.MONO_PASSTHRU 4;
.CONST $M.MUSIC_MANAGER.SYSMODE.MONO_STANDBY 5;
.CONST $M.MUSIC_MANAGER.SYSMODE.SUBWOOFER 6;
.CONST $M.MUSIC_MANAGER.SYSMODE.MONO_SUBWOOFER 7;
.CONST $M.MUSIC_MANAGER.SYSMODE.MAX_MODES 8;


.CONST $M.MUSIC_MANAGER.CONTROL.DAC_OVERRIDE 0x8000;
.CONST $M.MUSIC_MANAGER.CONTROL.MODE_OVERRIDE 0x2000;



.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CONFIG 0;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_CONFIG 1;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_GAIN_EXP 2;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_GAIN_MANT 3;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B2 4;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B1 5;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_B0 6;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_A2 7;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE1_A1 8;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B2 9;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B1 10;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_B0 11;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_A2 12;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE2_A1 13;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B2 14;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B1 15;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_B0 16;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_A2 17;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE3_A1 18;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B2 19;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B1 20;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_B0 21;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_A2 22;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE4_A1 23;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B2 24;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B1 25;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_B0 26;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_A2 27;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_STAGE5_A1 28;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_SCALE1 29;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_SCALE2 30;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_SCALE3 31;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_SCALE4 32;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ1_SCALE5 33;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_CONFIG 34;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_GAIN_EXP 35;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_GAIN_MANT 36;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B2 37;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B1 38;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_B0 39;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_A2 40;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE1_A1 41;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B2 42;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B1 43;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_B0 44;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_A2 45;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE2_A1 46;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B2 47;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B1 48;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_B0 49;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_A2 50;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE3_A1 51;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B2 52;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B1 53;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_B0 54;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_A2 55;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE4_A1 56;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B2 57;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B1 58;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_B0 59;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_A2 60;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_STAGE5_A1 61;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_SCALE1 62;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_SCALE2 63;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_SCALE3 64;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_SCALE4 65;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SPKR_EQ2_SCALE5 66;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_CONFIG 67;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_GAIN_EXP 68;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_GAIN_MANT 69;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_B2 70;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_B1 71;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_B0 72;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_A2 73;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_A1 74;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ1_SCALE 75;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_CONFIG 76;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_GAIN_EXP 77;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_GAIN_MANT 78;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_B2 79;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_B1 80;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_B0 81;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_A2 82;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_A1 83;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BOOST_EQ2_SCALE 84;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ_NUM_BANKS 85;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_NUM_BANDS 86;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_GAIN 87;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE1_TYPE 88;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE1_FC 89;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE1_GAIN 90;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE1_Q 91;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE2_TYPE 92;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE2_FC 93;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE2_GAIN 94;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE2_Q 95;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE3_TYPE 96;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE3_FC 97;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE3_GAIN 98;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE3_Q 99;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE4_TYPE 100;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE4_FC 101;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE4_GAIN 102;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE4_Q 103;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE5_TYPE 104;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE5_FC 105;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE5_GAIN 106;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ1_STAGE5_Q 107;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_NUM_BANDS 108;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_GAIN 109;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE1_TYPE 110;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE1_FC 111;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE1_GAIN 112;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE1_Q 113;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE2_TYPE 114;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE2_FC 115;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE2_GAIN 116;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE2_Q 117;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE3_TYPE 118;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE3_FC 119;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE3_GAIN 120;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE3_Q 121;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE4_TYPE 122;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE4_FC 123;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE4_GAIN 124;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE4_Q 125;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE5_TYPE 126;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE5_FC 127;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE5_GAIN 128;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ2_STAGE5_Q 129;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_NUM_BANDS 130;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_GAIN 131;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE1_TYPE 132;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE1_FC 133;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE1_GAIN 134;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE1_Q 135;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE2_TYPE 136;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE2_FC 137;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE2_GAIN 138;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE2_Q 139;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE3_TYPE 140;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE3_FC 141;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE3_GAIN 142;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE3_Q 143;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE4_TYPE 144;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE4_FC 145;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE4_GAIN 146;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE4_Q 147;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE5_TYPE 148;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE5_FC 149;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE5_GAIN 150;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ3_STAGE5_Q 151;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_NUM_BANDS 152;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_GAIN 153;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE1_TYPE 154;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE1_FC 155;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE1_GAIN 156;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE1_Q 157;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE2_TYPE 158;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE2_FC 159;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE2_GAIN 160;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE2_Q 161;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE3_TYPE 162;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE3_FC 163;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE3_GAIN 164;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE3_Q 165;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE4_TYPE 166;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE4_FC 167;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE4_GAIN 168;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE4_Q 169;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE5_TYPE 170;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE5_FC 171;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE5_GAIN 172;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ4_STAGE5_Q 173;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_NUM_BANDS 174;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_GAIN 175;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE1_TYPE 176;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE1_FC 177;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE1_GAIN 178;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE1_Q 179;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE2_TYPE 180;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE2_FC 181;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE2_GAIN 182;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE2_Q 183;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE3_TYPE 184;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE3_FC 185;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE3_GAIN 186;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE3_Q 187;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE4_TYPE 188;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE4_FC 189;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE4_GAIN 190;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE4_Q 191;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE5_TYPE 192;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE5_FC 193;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE5_GAIN 194;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ5_STAGE5_Q 195;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_NUM_BANDS 196;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_GAIN 197;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE1_TYPE 198;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE1_FC 199;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE1_GAIN 200;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE1_Q 201;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE2_TYPE 202;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE2_FC 203;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE2_GAIN 204;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE2_Q 205;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE3_TYPE 206;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE3_FC 207;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE3_GAIN 208;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE3_Q 209;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE4_TYPE 210;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE4_FC 211;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE4_GAIN 212;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE4_Q 213;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE5_TYPE 214;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE5_FC 215;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE5_GAIN 216;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_USER_EQ6_STAGE5_Q 217;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SDICONFIG 218;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DAC_GAIN_L 219;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DAC_GAIN_R 220;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_CONFIG 221;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A1 222;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A2 223;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A3 224;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A4 225;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_A5 226;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B1 227;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B2 228;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B3 229;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B4 230;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_B5 231;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_BASS_MANAGER_COEF_FREQ 232;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_REFLECTION_DELAY 233;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SE_MIX 234;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_THRESHOLD1 235;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_THRESHOLD1 236;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_THRESHOLD1 237;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_THRESHOLD1 238;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_EXPAND_RATIO1 239;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_LINEAR_RATIO1 240;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_COMPRESS_RATIO1 241;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_LIMIT_RATIO1 242;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_ATTACK_TC1 243;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_DECAY_TC1 244;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_ATTACK_TC1 245;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_DECAY_TC1 246;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC1 247;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_DECAY_TC1 248;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_ATTACK_TC1 249;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_DECAY_TC1 250;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_MAKEUP_GAIN1 251;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_THRESHOLD2 252;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_THRESHOLD2 253;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_THRESHOLD2 254;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_THRESHOLD2 255;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_EXPAND_RATIO2 256;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_LINEAR_RATIO2 257;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_COMPRESS_RATIO2 258;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_INV_LIMIT_RATIO2 259;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_ATTACK_TC2 260;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_EXPAND_DECAY_TC2 261;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_ATTACK_TC2 262;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LINEAR_DECAY_TC2 263;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_ATTACK_TC2 264;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_COMPRESS_DECAY_TC2 265;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_ATTACK_TC2 266;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_LIMIT_DECAY_TC2 267;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_MAKEUP_GAIN2 268;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SIGNAL_DETECT_THRESH 269;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_SIGNAL_DETECT_TIMEOUT 270;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DITHER_NOISE_SHAPE 271;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_0 272;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_1 273;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_2 274;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_3 275;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_4 276;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_5 277;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_6 278;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_7 279;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_8 280;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_DSP_USER_9 281;

.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC1_CONFIG 282;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC2_CONFIG 283;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC3_CONFIG 284;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC4_CONFIG 285;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC5_CONFIG 286;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC6_CONFIG 287;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC7_CONFIG 288;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC8_CONFIG 289;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC9_CONFIG 290;
.CONST $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC10_CONFIG 291;
.CONST $M.MUSIC_MANAGER.PARAMETERS.STRUCT_SIZE 292;
.linefile 13 "music_example.h" 2
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
.linefile 13 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cmpd100.h"
.CONST $CMPD100_VERSION 0x010004;


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
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/audio_proc_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stereo_3d_enhancement.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/stereo_3d_enhancement.h"
.CONST $stereo_3d_enhancement.INPUT_CH1_PTR_BUFFER_FIELD 0;
.CONST $stereo_3d_enhancement.INPUT_CH2_PTR_BUFFER_FIELD 1;
.CONST $stereo_3d_enhancement.OUTPUT_CH1_PTR_BUFFER_FIELD 2;
.CONST $stereo_3d_enhancement.OUTPUT_CH2_PTR_BUFFER_FIELD 3;
.CONST $stereo_3d_enhancement.DELAY_1_STRUC_FIELD 4;
.CONST $stereo_3d_enhancement.DELAY_2_STRUC_FIELD 5;
.CONST $stereo_3d_enhancement.COEFF_STRUC_FIELD 6;
.CONST $stereo_3d_enhancement.REFLECTION_DELAY_SAMPLES_FIELD 7;
.CONST $stereo_3d_enhancement.MIX_FIELD 8;
.CONST $stereo_3d_enhancement.SE_CONFIG_FIELD 9;
.CONST $stereo_3d_enhancement.ENABLE_BIT_MASK_FIELD 10;
.CONST $stereo_3d_enhancement.STRUC_SIZE 11;


.CONST $stereo_3d_enhancement.REFLECTION_DELAY 618;

.CONST $stereo_3d_enhancement.DELAY_BUFFER_SIZE 2208;
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
.linefile 14 "music_example.h" 2




.CONST $music_example.JITTER 3000;


.CONST $M.music_example.SPIMSG.STATUS 0x1007;
.CONST $M.music_example.SPIMSG.PARAMS 0x1008;
.CONST $M.music_example.SPIMSG.REINIT 0x1009;
.CONST $M.music_example.SPIMSG.VERSION 0x100A;
.CONST $M.music_example.SPIMSG.CONTROL 0x100B;
.CONST $M.music_example.SPIMSG.SPDIF_CONFIG 0x2000;

.CONST $music_example.VMMSG.READY 0x1000;
.CONST $music_example.VMMSG.SETMODE 0x1001;
.CONST $music_example.VMMSG.VOLUME 0x1002;
.CONST $music_example.VMMSG.SETPARAM 0x1004;
.CONST $music_example.VMMSG.CODEC 0x1006;
.CONST $music_example.VMMSG.PING 0x1008;
.CONST $music_example.VMMSG.PINGRESP 0x1009;
.CONST $music_example.VMMSG.SECPASSED 0x100c;
.CONST $music_example.VMMSG.SETSCOTYPE 0x100d;
.CONST $music_example.VMMSG.SETCONFIG 0x100e;
.CONST $music_example.VMMSG.SETCONFIG_RESP 0x100f;
.CONST $music_example.VMMSG.GETPARAM 0x1010;
.CONST $music_example.VMMSG.GETPARAM_RESP 0x1011;
.CONST $music_example.VMMSG.LOADPARAMS 0x1012;
.CONST $music_example.VMMSG.CUR_EQ_BANK 0x1014;
.CONST $music_example.VMMSG.PARAMS_LOADED 0x1015;
.CONST $music_example.VMMSG.APTX_PARAMS 0x1016;
.CONST $music_example.VMMSG.APTX_SECURITY 0x1017;

.const $music_example.VMMSG.SIGNAL_DETECT_SET_PARMS 0x1018;
.const $music_example.VMMSG.SIGNAL_DETECT_STATUS 0x1019;
.const $music_example.VMMSG.SOFT_MUTE 0x101a;


.CONST $music_example.VMMSG.SETPLUGIN 0x1020;


.CONST $music_example.VMMSG.LATENCY_REPORTING 0x1023;




.const $music_example.GAIAMSG.SET_USER_PARAM 0x121a;
.const $music_example.GAIAMSG.GET_USER_PARAM 0x129a;
.const $music_example.GAIAMSG.SET_USER_GROUP_PARAM 0x121b;
.const $music_example.GAIAMSG.GET_USER_GROUP_PARAM 0x129b;

.const $music_example.GAIAMSG.SET_USER_PARAM_RESP 0x321a;
.const $music_example.GAIAMSG.GET_USER_PARAM_RESP 0x329a;
.const $music_example.GAIAMSG.SET_USER_GROUP_PARAM_RESP 0x321b;
.const $music_example.GAIAMSG.GET_USER_GROUP_PARAM_RESP 0x329b;


.CONST $music_example.REINITIALIZE 1;


.CONST $music_example.MUTE_CONTROL.OFFSET_INPUT_PTR 0;
.CONST $music_example.MUTE_CONTROL.OFFSET_INPUT_LEN 1;
.CONST $music_example.MUTE_CONTROL.OFFSET_NUM_SAMPLES 2;
.CONST $music_example.MUTE_CONTROL.OFFSET_MUTE_VAL 3;
.CONST $music_example.MUTE_CONTROL.STRUC_SIZE 4;
.linefile 89 "music_example.h"
    .CONST $music_example.NUM_SAMPLES_PER_FRAME 360;





.CONST $music_example.peq.INPUT_ADDR_FIELD 0;
.CONST $music_example.peq.OUTPUT_ADDR_FIELD 1;
.CONST $music_example.peq.MAX_STAGES_FIELD 2;
.CONST $music_example.peq.PARAM_PTR_FIELD 3;
.CONST $music_example.peq.DELAYLINE_ADDR_FIELD 4;
.CONST $music_example.peq.COEFS_ADDR_FIELD 5;
.CONST $music_example.peq.NUM_STAGES_FIELD 6;
.CONST $music_example.peq.DELAYLINE_SIZE_FIELD 7;
.CONST $music_example.peq.COEFS_SIZE_FIELD 8;
.CONST $music_example.peq.BLOCK_SIZE_FIELD 9;
.CONST $music_example.peq.SCALING_ADDR_FIELD 10;
.CONST $music_example.peq.GAIN_EXPONENT_ADDR_FIELD 11;
.CONST $music_example.peq.GAIN_MANTISA_ADDR_FIELD 12;
.CONST $music_example.peq.BYPASS_BIT_MASK_FIELD 13;

.CONST $music_example.peq.STRUC_SIZE 14;


.CONST $music_example.peq.BS_COEFFS_PTR_FIELD 0;
.CONST $music_example.peq.BS_SCALE_PTR_FIELD 1;
.CONST $music_example.peq.BS_NUMSTAGES_FIELD 2;
.CONST $music_example.peq.BS_GAIN_EXP_PTR_FIELD 3;
.CONST $music_example.peq.BS_GAIN_MANT_PTR_FIELD 4;
.CONST $music_example.peq.BS_STRUC_SIZE 5;


.CONST $music_example.SBC_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC1_CONFIG;
.CONST $music_example.MP3_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC2_CONFIG;
.CONST $music_example.FASTSTREAM_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC3_CONFIG;
.CONST $music_example.USB_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC4_CONFIG;
.CONST $music_example.APTX_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC5_CONFIG;
.CONST $music_example.AAC_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC6_CONFIG;
.CONST $music_example.ANALOGUE_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC7_CONFIG;
.CONST $music_example.APTX_ACL_SPRINT_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC8_CONFIG;
.CONST $music_example.SPDIF_CODEC_CONFIG $M.MUSIC_MANAGER.PARAMETERS.OFFSET_CODEC9_CONFIG;


.CONST $music_example.SBC_CODEC_TYPE 0;
.CONST $music_example.MP3_CODEC_TYPE 1;
.CONST $music_example.FASTSTREAM_CODEC_TYPE 2;
.CONST $music_example.USB_CODEC_TYPE 3;
.CONST $music_example.APTX_CODEC_TYPE 4;
.CONST $music_example.AAC_CODEC_TYPE 5;
.CONST $music_example.ANALOGUE_CODEC_TYPE 6;
.CONST $music_example.APTX_ACL_SPRINT_CODEC_TYPE 7;
.CONST $music_example.SPDIF_CODEC_TYPE 8;


.CONST $music_example.CODEC_STATS_SIZE ($M.MUSIC_MANAGER.STATUS.BLOCK_SIZE - $M.MUSIC_MANAGER.STATUS.CODEC_FS_OFFSET);

.CONST $music_example.12dB 12.041199826559248;
.CONST $music_example.DEFAULT_MASTER_VOLUME ((10.0**(0 + $music_example.12dB/20.0))/16.0);
.CONST $music_example.DEFAULT_TRIM_VOLUME ((10.0**(0/20.0))/16.0);
.CONST $music_example.LIMIT_THRESHOLD (log2(((10.0**(-1.0/20.0))/16.0))/128.0);
.CONST $music_example.LIMIT_RATIO (1.0 - (1.0/20));
.CONST $music_example.LIMIT_THRESHOLD_LINEAR ((10.0**(-1.0/20.0))/16.0);
.CONST $music_example.MAX_VM_TRIM_VOLUME_dB round($music_example.12dB*60.0);
.CONST $music_example.MIN_VM_TRIM_VOLUME_dB round(-$music_example.12dB*60.0);
.CONST $music_example.MUTE_MASTER_VOLUME 0;
.linefile 12 "codec_decoder.h" 2
.linefile 87 "codec_decoder.h"
.CONST $OUTPUT_AUDIO_CBUFFER_SIZE (($music_example.NUM_SAMPLES_PER_FRAME*2) + 2*(1500 * 48000/1000000));







.CONST $INVALID_IO -1;
.CONST $SBC_IO 1;
.CONST $MP3_IO 2;
.CONST $AAC_IO 3;
.CONST $FASTSTREAM_IO 4;
.CONST $USB_IO 5;
.CONST $APTX_IO 6;
.CONST $APTX_ACL_SPRINT_IO 7;
.CONST $ANALOGUE_IO 8;
.CONST $SPDIF_IO 9;
.linefile 115 "codec_decoder.h"
.CONST $AUDIO_IF_MASK (0x00ff);
.CONST $LOCAL_PLAYBACK_MASK (0x0100);
.CONST $PCM_PLAYBACK_MASK (0x0200);
.CONST $PCM_END_DETECTION_TIME_OUT (30000);

.CONST $AUDIO_LEFT_OUT_PORT ($cbuffer.WRITE_PORT_MASK + 0);
.CONST $AUDIO_RIGHT_OUT_PORT ($cbuffer.WRITE_PORT_MASK + 1);



    .CONST $AUDIO_ESCO_SUB_OUT_PORT ($cbuffer.WRITE_PORT_MASK | $cbuffer.FORCE_LITTLE_ENDIAN | $cbuffer.FORCE_NO_SATURATE | $cbuffer.FORCE_16BIT_WORD) + 2;

    .const $AUDIO_L2CAP_SUB_OUT_PORT ($cbuffer.WRITE_PORT_MASK + $cbuffer.FORCE_PCM_AUDIO + 3);
    .CONST $HEADER_L2CAP_SUB_OUT_PORT (($cbuffer.WRITE_PORT_MASK | $cbuffer.FORCE_LITTLE_ENDIAN | $cbuffer.FORCE_16BIT_WORD | $cbuffer.FORCE_NO_SIGN_EXTEND) + 3);

    .const $ESCO_SUB_AUDIO_PACKET_SIZE 9;
    .const $L2CAP_SUB_AUDIO_PACKET_SIZE 18;

    .CONST $L2CAP_SUB_ALIGNMENT_DELAY 3020;
    .CONST $ESCO_SUB_ALIGNMENT_DELAY 650;
    .CONST $L2CAP_FRAME_PROCESSING_RATE 7500;
    .CONST $SUBWOOFER_ESCO_PORT_RATE 3750;
    .CONST $L2CAP_PACKET_SIZE_BYTES 50;
    .CONST $L2CAP_HEADER_SIZE_WORDS 7;




.CONST $CON_IN_PORT ($cbuffer.READ_PORT_MASK + 0);



.CONST $CON_IN_LEFT_PORT ($cbuffer.READ_PORT_MASK + 0);
.CONST $CON_IN_RIGHT_PORT ($cbuffer.READ_PORT_MASK + 1);



.CONST $TONE_IN_PORT (($cbuffer.READ_PORT_MASK | $cbuffer.FORCE_PCM_AUDIO) + 3);
.linefile 13 "sr_adjustment.h" 2

.CONST $sra.NO_ACTIVITY_PERIOD ((50*8000)/1000);
.CONST $sra.ACTIVITY_PERIOD_BEFORE_START ((200*8000)/1000);


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
.CONST $sra.CODEC_DATA_READ_FIELD 6;
.CONST $sra.NO_CODEC_DATA_COUNTER_FIELD 7;
.CONST $sra.ACTIVE_PERIOD_COUNTER_FIELD 8;
.CONST $sra.MODE_FIELD 9;
.CONST $sra.CODEC_CBUFFER_START_ADDR_TAG_FIELD 10;
.CONST $sra.CODEC_CBUFFER_END_ADDR_TAG_FIELD 11;
.CONST $sra.TAG_TIME_COUNTER_FIELD 12;
.CONST $sra.RATECALC_MODE_FIELD 13;
.CONST $sra.CODEC_CBUFFER_PREV_READ_ADDR_FIELD 14;
.CONST $sra.AUDIO_CBUFFER_PREV_WRITE_ADDR_FIELD 15;
.CONST $sra.AUDIO_TOTAL_DECODED_SAMPLES_FIELD 16;
.CONST $sra.SRA_RATE_FIELD 17;
.CONST $sra.RESET_HIST_FIELD 18;
.CONST $sra.HIST_INDEX_FIELD 19;
.CONST $sra.SAVIN_STATE_FIELD 20;
.CONST $sra.BUFFER_LEVEL_COUNTER_FIELD 21;
.CONST $sra.BUFFER_LEVEL_ACC_FIELD 22;
.CONST $sra.FIX_VALUE_FIELD 23;
.CONST $sra.RATE_BEFORE_FIX_FIELD 24;
.CONST $sra.LONG_TERM_RATE_FIELD 25;
.CONST $sra.LONG_TERM_RATE_DETECTED_FIELD 26;
.CONST $sra.AVERAGE_LEVEL_FIELD 27;
.CONST $sra.TARGET_LATENCY_MS_FIELD 28;
.CONST $sra.CURRENT_LATENCY_PTR_FIELD 29;
.CONST $sra.LATENCY_ACC_FIELD 30;
.CONST $sra.AVERAGE_LATENCY_FIELD 31;
.CONST $sra.HIST_BUFF_FIELD 32;
.CONST $sra.STRUC_SIZE ($sra.HIST_BUFF_FIELD+$sra.BUFF_SIZE);
.linefile 13 "relay_conn.asm" 2
.linefile 1 "relay_conn.h" 1
.linefile 23 "relay_conn.h"
.CONST $RELAY_PORT ($cbuffer.WRITE_PORT_MASK + 4);
.CONST $TWS_ALIGNMENT_DELAY 11000;
.CONST $TWS_SYNC_TOLERANCE 500;
.CONST $ROLE_TIMEOUT 1200;
.CONST $TWS_RELAY_TIMEOUT 8-1;
.CONST $TWS_CHUNK_SIZE 672;
.CONST $TWS_CONNECTION_HOLDOFF 0;
.CONST $TWS_STANDALONE_CNT 100;
.CONST $TWS_SOFTMUTE_TIME 500000;
.CONST $TWS_ROUTING_MUTE_TIME 40000;

.CONST $UNKNOWN 0;
.CONST $SLAVE 1;
.CONST $MASTER 2;




.CONST $MESSAGE_VM_STREAM_RELAY_MODE 0x1028;
.CONST $MESSAGE_VM_STREAM_RELAY_MODE_ACK 0x1024;
.CONST $MESSAGE_VM_TWS_ROUTING_MODE 0x7157;
.CONST $MESSAGE_VM_DEVICE_TRIMS 0x7158;
.CONST $MESSAGE_VM_EXTERNAL_VOLUME_ENABLE 0x7159;
.CONST $MESSAGE_DSP_VOLUME 0x715A;
.CONST $MESSAGE_DSP_TWS_ERROR 0x715B;


.CONST $TWS_VERSION_UNSUPPORTED 1;


.CONST $NO_RELAY_MODE 0;
.CONST $SHAREME_MODE 1;
.CONST $TWS_MASTER_MODE 2;
.CONST $TWS_SLAVE_MODE 3;
.CONST $ERR_RELAY_LOST 0xFFF0;
.CONST $ERR_UNSUPPORTED_MODE 0xFFFF;

.CONST $TWS_ROUTING_STEREO 0;
.CONST $TWS_ROUTING_LEFT 1;
.CONST $TWS_ROUTING_RIGHT 2;
.CONST $TWS_ROUTING_DMIX 3;

.CONST $TWS_VOL_MESSAGE_SIZE 5;
.CONST $TWS_V3_PROTOCOL_ID 0x030000;




.CONST $relay.INPUT_CBUFFER_FIELD 0;
.CONST $relay.INTERNAL_CBUFFER_PTR_FIELD 1;
.CONST $relay.RELAY_CBUFFER_FIELD 2;
.CONST $relay.AV_DECODE_STRUC_FIELD 3;
.CONST $relay.CODEC_GET_BITPOS 4;
.CONST $relay.CODEC_GETBITS 5;
.CONST $relay.TWS_HEADER_FIELD 6;
.CONST $relay.IS_APTX_FIELD 7;
.CONST $relay.struct_size 8;

.CONST $tws.header.SIZE_FIELD 0;
.CONST $tws.header.ID_FIELD 1;
.CONST $tws.header.ROUTING_MODE_FIELD 2;
.CONST $tws.header.PLAYBACK_TIME_FIELD 3;
.CONST $tws.header.SRA_TARGET_RATE_FIELD 4;
.CONST $tws.header.SYS_VOL_FIELD 5;
.CONST $tws.header.MASTER_VOL_FIELD 6;
.CONST $tws.header.TONE_VOL_FIELD 7;
.CONST $tws.header.TRIM_LEFT_FIELD 8;
.CONST $tws.header.TRIM_RIGHT_FIELD 9;
.CONST $tws.header.SRA_ACTUAL_RATE_FIELD 10;
.CONST $tws.header.struct_size 11;
.linefile 14 "relay_conn.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/sbc_library.h" 1
.linefile 10 "C:/ADK3.5/kalimba/lib_sets/sdk/include/sbc_library.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/sbc.h" 1
.linefile 27 "C:/ADK3.5/kalimba/lib_sets/sdk/include/sbc.h"
   .CONST $sbc.MAX_AUDIO_FRAME_SIZE_IN_WORDS 128;
   .CONST $sbc.MAX_SBC_FRAME_SIZE_IN_BYTES 512;
   .CONST $sbc.MIN_SBC_FRAME_SIZE_IN_BYTES 20;
   .CONST $sbc.CAN_IDLE 0;
   .CONST $sbc.DONT_IDLE 1;
   .CONST $sbc.WBS_SBC_FRAME_LENGTH_IN_BYTES 62;
   .CONST $sbc.WBS_SBC_FRAME_LENGTH_IN_WORDS 31;
   .CONST $sbc.SBC_NOT_SYNC 99;



   .CONST $sbcdec.STATE_STRUC_SIZE 326;
   .CONST $sbcend.STATE_STRUC_SIZE 172;



    .CONST $sbc.mem.AUDIO_SAMPLE_JS_FIELD 0;
    .CONST $sbc.mem.ANALYSIS_COEFS_M8_FIELD 1;
    .CONST $sbc.mem.ANALYSIS_COEFS_M4_FIELD 2;
    .CONST $sbc.mem.ANALYSIS_XCH1_FIELD 3;
    .CONST $sbc.mem.ANALYSIS_XCH2_FIELD 4;
    .CONST $sbc.mem.ANALYSIS_Y_FIELD 5;
    .CONST $sbc.mem.LEVEL_COEFS_FIELD 6;
    .CONST $sbc.mem.PRE_POST_PROC_STRUC_FIELD 7;
    .CONST $sbc.mem.ENC_SETTING_NROF_SUBBANDS_FIELD 8;
    .CONST $sbc.mem.ENC_SETTING_NROF_BLOCKS_FIELD 9;
    .CONST $sbc.mem.ENC_SETTING_SAMPLING_FREQ_FIELD 10;
    .CONST $sbc.mem.ENC_SETTING_CHANNEL_MODE_FIELD 11;
    .CONST $sbc.mem.ENC_SETTING_ALLOCATION_METHOD_FIELD 12;
    .CONST $sbc.mem.ENC_SETTING_BITPOOL_FIELD 13;
    .CONST $sbc.mem.ENC_SETTING_FORCE_WORD_ALIGN_FIELD 14;
    .CONST $sbc.mem.PUT_NEXTWORD_FIELD 15;
    .CONST $sbc.mem.PUT_BITPOS_FIELD 16;
    .CONST $sbc.mem.ANALYSIS_XCH1PTR_FIELD 17;
    .CONST $sbc.mem.ANALYSIS_XCH2PTR_FIELD 18;
    .CONST $sbc.mem.WBS_SEND_FRAME_COUNTER_FIELD 19;

    .CONST $sbc.mem.AUDIO_SAMPLE_FIELD 20;
    .CONST $sbc.mem.WIN_COEFS_M8_FIELD 21;
    .CONST $sbc.mem.WIN_COEFS_M4_FIELD 22;
    .CONST $sbc.mem.LOUDNESS_OFFSET_FIELD 23;
    .CONST $sbc.mem.SCALE_FACTOR_FIELD 24;
    .CONST $sbc.mem.SCALE_FACTOR_JS_FIELD 25;
    .CONST $sbc.mem.BITNEED_FIELD 26;
    .CONST $sbc.mem.BITS_FIELD 27;
    .CONST $sbc.mem.SAMPLING_FREQ_FIELD 28;
    .CONST $sbc.mem.NROF_BLOCKS_FIELD 29;
    .CONST $sbc.mem.CHANNEL_MODE_FIELD 30;
    .CONST $sbc.mem.NROF_CHANNELS_FIELD 31;
    .CONST $sbc.mem.ALLOCATION_METHOD_FIELD 32;
    .CONST $sbc.mem.NROF_SUBBANDS_FIELD 33;
    .CONST $sbc.mem.BITPOOL_FIELD 34;
    .CONST $sbc.mem.FRAMECRC_FIELD 35;
    .CONST $sbc.mem.CRC_CHECKSUM_FIELD 36;
    .CONST $sbc.mem.FORCE_WORD_ALIGN_FIELD 37;
    .CONST $sbc.mem.JOIN_FIELD 38;
    .CONST $sbc.mem.JOIN_1_FIELD 39;
    .CONST $sbc.mem.JOIN_2_FIELD 40;
    .CONST $sbc.mem.JOIN_3_FIELD 41;
    .CONST $sbc.mem.JOIN_4_FIELD 42;
    .CONST $sbc.mem.JOIN_5_FIELD 43;
    .CONST $sbc.mem.JOIN_6_FIELD 44;
    .CONST $sbc.mem.JOIN_7_FIELD 45;
    .CONST $sbcenc.mem.STRUC_SIZE 46;

    .CONST $sbc.mem.SYNTHESIS_COEFS_M8_FIELD 46;
    .CONST $sbc.mem.SYNTHESIS_COEFS_M4_FIELD 47;
    .CONST $sbc.mem.LEVELRECIP_COEFS_FIELD 48;
    .CONST $sbc.mem.BITMASK_LOOKUP_FIELD 49;
    .CONST $sbc.mem.SYNTHESIS_VCH1_FIELD 50;
    .CONST $sbc.mem.SYNTHESIS_VCH2_FIELD 51;
    .CONST $sbc.mem.CONVERT_TO_MONO_FIELD 52;
    .CONST $sbc.mem.FRAME_UNDERFLOW_FIELD 53;
    .CONST $sbc.mem.FRAME_CORRUPT_FIELD 54;
    .CONST $sbc.mem.NUM_BYTES_AVAILABLE_FIELD 55;
    .CONST $sbc.mem.WBS_SBC_FRAME_OK_FIELD 56;
    .CONST $sbc.mem.CUR_FRAME_LENGTH_FIELD 57;
    .CONST $sbc.mem.RETURN_ON_CORRUPT_FRAME_FIELD 58;
    .CONST $sbc.mem.GET_BITPOS_FIELD 59;
    .CONST $sbc.mem.SYNTHESIS_VCH1PTR_FIELD 60;
    .CONST $sbc.mem.SYNTHESIS_VCH2PTR_FIELD 61;
    .CONST $sbc.mem.WBS_FRAME_BUFFER_PTR_FIELD 62;
    .CONST $sbc.mem.WBS_SYNC_FIELD 63;
    .CONST $sbc.mem.WBS_BYTES_IN_FRAME_BUFFER_FIELD 64;
    .CONST $sbc.mem.WBS_STICKY_BFI_FIELD 65;
    .CONST $sbc.mem.WBS_PAYLOAD_ALIGN_FIELD 66;
    .CONST $sbc.mem.TIMESTAMP_T1_FIELD 67;
    .CONST $sbc.mem.TIMESTAMP_T2_FIELD 68;


    .CONST $sbc.mem.STRUC_SIZE 69;
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/sbc_library.h" 2
.linefile 15 "relay_conn.asm" 2

.MODULE $M.tws;
   .DATASEGMENT DM;

   .VAR/DMCIRC $tws.delay_L[1000];
   .VAR/DMCIRC $tws.delay_R[1000];
   .VAR/DMCIRC $relay_buffer[3096];
   .VAR $relay.mode_message_struc[$message.STRUC_SIZE];
   .VAR $tws.routing_mode_message_struc[$message.STRUC_SIZE];
   .VAR $tws.external_volume_enable_message_struc[$message.STRUC_SIZE];
   .VAR $tws.device_trim_message_struc[$message.STRUC_SIZE];

   .VAR $codec_in_cbuffer_int_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($codec_in),
      &$codec_in,
      &$codec_in;
   .VAR $relay_cbuffer_struc[$cbuffer.STRUC_SIZE] =
      LENGTH($relay_buffer),
      &$relay_buffer,
      &$relay_buffer;

   .VAR $relay_copy_struc[] =
      &$relay_copy_op,
      1,
      &$relay_cbuffer_struc,
      1,
      $RELAY_PORT;
.linefile 57 "relay_conn.asm"
   .BLOCK $relay_copy_op;
      .VAR $relay_copy_op.next = $cbops.NO_MORE_OPERATORS;
      .VAR $relay_copy_op.func = &$cbops.copy_op;
      .VAR $relay_copy_op.param[$cbops.copy_op.STRUC_SIZE] =
         0,
         1;
   .ENDBLOCK;


   .VAR $current_dac_sampling_frequency = 0;

   .VAR $get_tws_routing_from_vm_struc[$message.STRUC_SIZE];


   .VAR $send_vol_to_vm_timer_struc[$timer.STRUC_SIZE];
   .VAR $soft_mute_timer_struc[$timer.STRUC_SIZE];


   .VAR $relay_struc[$relay.struct_size]=
        &$codec_in_cbuffer_struc,
        &$codec_in_cbuffer_int_struc,
        &$relay_cbuffer_struc,
        &$decoder_codec_stream_struc,
        0,
        0,
        0,
        0;

   .VAR $tws.header_struc[$tws.header.struct_size]=
        10,
        4412242,
        $TWS_V3_PROTOCOL_ID,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0;

   .VAR $tws.wallclock_obj[$wall_clock.STRUC_SIZE] =
      0, 0, 0, 0, 0, 0, &$tws.roleswitch_detect, 0 ...;

   .VAR $tws.bdaddr_message_struc[$message.STRUC_SIZE];
   .VAR $tws.set_synchronized_data_message_struc[$timer.STRUC_SIZE];
   .VAR $tws.softmute_data_timer_struc[$timer.STRUC_SIZE];
   .VAR $tws.warp_timer_id;
   .VAR $tws.volume_timer_id;
   .VAR $tws.scheduled_sra;
   .VAR $tws.synchronised_sra;
   .VAR $tws.slave_sra;
   .VAR $tws.message_volume_struc[$TWS_VOL_MESSAGE_SIZE];
   .VAR $tws.scheduled_volume_struc[$TWS_VOL_MESSAGE_SIZE];
   .VAR $tws.local_mute_volume_struc[$TWS_VOL_MESSAGE_SIZE] =
        15,
        -7200,
        0,
        0,
        0;
   .VAR $tws.local_saved_volume_struc[$TWS_VOL_MESSAGE_SIZE];
   .VAR $tws.device_trim_master = 0;
   .VAR $tws.device_trim_slave = 0;
   .VAR $tws.message_routing_mode_master = 0;
   .VAR $tws.message_routing_mode_slave = 0;
   .VAR $tws.scheduled_routing_mode = 0;
   .VAR $tws.routing_mode = 0;
   .VAR $tws.started_streaming = 0;
   .VAR $relay.mode = 0;
   .VAR $tws.external_volume_enable = 0;
   .VAR $tws.master_enabled = 0;
   .VAR $tws.wired_mode_enabled = 0;
   .VAR $tws.insertion_counter = 0;
   .VAR $tws.started_streaming_counter = 0;
   .VAR $tws.zero = 0;
   .VAR $tws.alpha = 0.05;
   .VAR $tws.average_playback_difference = 0;
   .VAR $tws.average_playback_difference_old = 0;
   .VAR $tws.wallclock_running=0;
   .VAR $tws.decode_cnt = 0;
   .VAR $tws.initial_holdoff = 0;
   .VAR $tws.timeout_cnt=0;
   .VAR $tws.local_mute = 0;
.linefile 171 "relay_conn.asm"
.ENDMODULE;
.linefile 187 "relay_conn.asm"
.MODULE $M.relay.init;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $relay.init:

   push rLink;


   r1 = &$relay.mode_message_struc;
   r2 = $MESSAGE_VM_STREAM_RELAY_MODE;
   r3 = &$relay.mode_message_handler;
   call $message.register_handler;
.linefile 256 "relay_conn.asm"
done:
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 285 "relay_conn.asm"
.MODULE $M.tws.bluetooth_address_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$tws.bluetooth_address_handler:
   push rLink;



   r1 = r1 LSHIFT -8;
   M[$tws.wallclock_obj + $wall_clock.BT_ADDR_TYPE_FIELD] = r1;
   M[$tws.wallclock_obj + $wall_clock.BT_ADDR_WORD0_FIELD] = r2;
   M[$tws.wallclock_obj + $wall_clock.BT_ADDR_WORD1_FIELD] = r3;
   M[$tws.wallclock_obj + $wall_clock.BT_ADDR_WORD2_FIELD] = r4;


   r1 = &$tws.wallclock_obj;

   NULL = M[r1 + $wall_clock.NEXT_ADDR_FIELD];
   if Z call $wall_clock.enable;

   jump $pop_rLink_and_rts;



.ENDMODULE;
.linefile 326 "relay_conn.asm"
.MODULE $M.tws.audio_routing;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR $num_samples;

   $tws.audio_routing:
   push rLink;
   call $block_interrupts;

  r0 = M[$music_example.SystemVolume];
  M[$tws.local_mute_volume_struc +0] = r0;




   null = r2 - $TWS_ROUTING_STEREO;
   if Z jump done_with_routing;
   M0 = -r3;

   r0 = $audio_out_left_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;

   r0 = $audio_out_right_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;

   r0 = M[I0,M0];
   r4 = M[I4,M0];

   r10 = r3;
   do tws_audio_routing_loop;
      null = r2 - $TWS_ROUTING_LEFT;
      if NZ jump check_right;
      r0 = M[I0,1];
      M[I4,1] = r0;
      jump continue_loop;

   check_right:
      null = r2 - $TWS_ROUTING_RIGHT;
      if NZ jump check_dmix;

      r0 = M[I4,1];
      M[I0,1] = r0;
      jump continue_loop;

   check_dmix:
      null = r2 - $TWS_ROUTING_DMIX;
      if NZ jump done_with_routing;
      r0 = M[I0,0];
      r1 = M[I4,0];
      r0 = r0 ASHIFT -1;
      r1 = r1 ASHIFT -1;
      r0 = r1 + r0;
      M[I0,1] = r0;
      M[I4,1] = r0;

   continue_loop:
   nop;
   tws_audio_routing_loop:

   r0 = $audio_out_left_cbuffer_struc;
   r1 = I0;
   call $cbuffer.set_write_address;

   r0 = $audio_out_right_cbuffer_struc;
   r1 = I4;
   call $cbuffer.set_write_address;

   done_with_routing:
   L0 = 0;
   L4 = 0;
   M0 = 0;

   call $unblock_interrupts;
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 423 "relay_conn.asm"
.MODULE $M.shareme.enable;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $shareme.enable:
   M[$relay_struc+ $relay.TWS_HEADER_FIELD] = NULL;
   rts;

.ENDMODULE;
.linefile 448 "relay_conn.asm"
.MODULE $M.tws.master.enable;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.master.enable:


   push rLink;

   call $tws.local_volume_mute;

   r2 = $TWS_SOFTMUTE_TIME;
   r1 = &$tws.softmute_data_timer_struc;
   r3 = &$tws.local_volume_unmute;
   call $timer.schedule_event_in;

   r3 = $RELAY_PORT;
   call $cbuffer.is_it_enabled;
   if Z jump done;

   r1 = M[$tws.decode_cnt];
   null = r1 - $TWS_STANDALONE_CNT;
   if NEG jump no_holdoff;

   r1 = $TWS_CONNECTION_HOLDOFF;
   M[$tws.initial_holdoff] = r1;

   no_holdoff:
   M[$tws.master_enabled] = r3;

   r1 = &$tws.header_struc;
   M[$relay_struc+ $relay.TWS_HEADER_FIELD] = r1;

   r3 = &$tws.local_saved_volume_struc;
   r2 = length($tws.message_volume_struc);
   r1 = &$tws.message_volume_struc;
   call $tws.copy_array;

   call $block_interrupts;
   r3 = $music_example.VMMSG.VOLUME;
   call $message.unregister_handler;


   r1 = &$M.music_example_message.volume_message_struc;
   r2 = $music_example.VMMSG.VOLUME;
   r3 = &$tws.volume_message_handler;
   call $message.register_handler;

   call $unblock_interrupts;
.linefile 505 "relay_conn.asm"
   r1 = &$tws.routing_mode_message_struc;
   r2 = $MESSAGE_VM_TWS_ROUTING_MODE;
   r3 = &$tws.routing_message_handler;
   call $message.register_handler;

   r1 = &$tws.device_trim_message_struc;
   r2 = $MESSAGE_VM_DEVICE_TRIMS;
   r3 = &$tws.device_trim_message_handler;
   call $message.register_handler;

   r1 = &$tws.external_volume_enable_message_struc;
   r2 = $MESSAGE_VM_EXTERNAL_VOLUME_ENABLE;
   r3 = &$tws.external_volume_enable_message_handler;
   call $message.register_handler;

   call $tws.configure_synchronised_warping;

   r1 = $TWS_ALIGNMENT_DELAY;
   M[$M.main.samples_latency_measure + 0] = r1;
   M[$M.system_config.data.delay_left + $audio_proc.delay.DELAY_FIELD] = r1;
   M[$M.system_config.data.delay_right + $audio_proc.delay.DELAY_FIELD] = r1;

   call $M.relay.mode_message_handler.ack;

   r1 = 1;
   M[$tws.started_streaming] = r1;

   done:

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 553 "relay_conn.asm"
.MODULE $M.tws.wired_mode.enable;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.wired_mode.enable:

   push rLink;

   r3 = $RELAY_PORT;
   call $cbuffer.is_it_enabled;
   if Z jump done;

   Null = M[$tws.master_enabled];
   if Z jump done;

   Null = M[$tws.wired_mode_enabled];
   if NZ jump done;

   r0 = M[$app_config.io];
   null = r0 - $USB_IO;
   if Z jump enable;

   null = r0 - $ANALOGUE_IO;
   if NZ jump done;


   r0 = &$tws.zero;
   M[$sra_rate_addr] = r0;

   enable:
   M[$tws.wired_mode_enabled] = r3;


   r0 = &$audio_in_left_cbuffer_struc;
   M[$usb_audio_in_copy_struc + 1] = r0;
   r0 = &$audio_in_right_cbuffer_struc;
   M[$usb_audio_in_copy_struc + 2] = r0;



   r0 = &$audio_in_left_cbuffer_struc;
   M[$analogue_audio_in_copy_struc + 5] = r0;
   r0 = &$audio_in_right_cbuffer_struc;
   M[$analogue_audio_in_copy_struc + 6] = r0;


   r0 = M[$sbc_dec_initialized];
   if NZ jump done;


   r0 = $sbcdec.frame_decode;
   M[$decoder_codec_stream_struc + $codec.av_decode.ADDR_FIELD] = r0;
   r0 = $sbcdec.reset_decoder;
   M[$decoder_codec_stream_struc + $codec.av_decode.RESET_ADDR_FIELD] = r0;
   r0 = $sbcdec.silence_decoder;
   M[$decoder_codec_stream_struc + $codec.av_decode.SILENCE_ADDR_FIELD] = r0;




   r5 = $decoder_codec_stream_struc + $codec.av_decode.DECODER_STRUC_FIELD;
   call $sbcdec.init_static_decoder;

   r1 = 1;
   M[$sbc_dec_initialized] =r1;

   done:
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 639 "relay_conn.asm"
.MODULE $M.tws.wired_mode.disable;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.wired_mode.disable:

   push rLink;

   null = M[$tws.wired_mode_enabled];
   if Z jump done;

   M[$tws.wired_mode_enabled] = null;
   r0 = $sra_struct + $sra.SRA_RATE_FIELD;

   M[$sra_rate_addr] = r0;

   r1 = 1;
   M[$codec_reset_needed]=r1;

   r0 = &$audio_in_left_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   r1 = r0;
   r0 = &$audio_in_left_cbuffer_struc;
   call $cbuffer.set_write_address;

   r0 = &$audio_out_left_cbuffer_struc;
   M[$analogue_audio_in_copy_struc + 5] = r0;
   M[$usb_audio_in_copy_struc + 1] = r0;
   r0 = &$audio_out_right_cbuffer_struc;
   M[$analogue_audio_in_copy_struc + 6] = r0;
   M[$usb_audio_in_copy_struc + 2] = r0;
   done:
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 690 "relay_conn.asm"
.MODULE $M.tws.disable;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.disable:

   push rLink;

   call $tws.local_volume_mute;




   r2 = $TWS_SOFTMUTE_TIME;
   r1 = &$tws.softmute_data_timer_struc;
   r3 = &$tws.local_volume_unmute;
   call $timer.schedule_event_in;



   M[$relay_struc+ $relay.TWS_HEADER_FIELD] = NULL;



   call $block_interrupts;
   r3 = $music_example.VMMSG.VOLUME;
   call $message.unregister_handler;

   r3 = $MESSAGE_VM_TWS_ROUTING_MODE;
   call $message.unregister_handler;

   r3 = $MESSAGE_VM_DEVICE_TRIMS;
   call $message.unregister_handler;

   r3 = $MESSAGE_VM_EXTERNAL_VOLUME_ENABLE;
   call $message.unregister_handler;
   call $unblock_interrupts;





   r1 = &$M.music_example_message.volume_message_struc;
   r2 = $music_example.VMMSG.VOLUME;
   r3 = &$M.music_example_message.Volume.func;
   call $message.register_handler;


   r0 = M[$sra_rate_addr];

   M[$audio_out_rate_adjustment_and_shift_op_mono.param + $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD] = r0;
   M[$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD] = r0;



   r1 = &$tws.wallclock_obj;
   call $wall_clock.disable;
   r1 = &$tws.wallclock_obj;
   M[r1 + $wall_clock.NEXT_ADDR_FIELD]=NULL;
   M[r1 + $wall_clock.ADJUSTMENT_VALUE_FIELD]=NULL;
   M[$tws.wallclock_running] = NULL;

   r2 = M[$tws.warp_timer_id];
   if NZ call $timer.cancel_event;



   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 776 "relay_conn.asm"
.MODULE $M.tws.slave.enable;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.slave.enable:

   push rLink;
   call $tws.local_volume_mute;

   r2 = $TWS_SOFTMUTE_TIME;
   r1 = &$tws.softmute_data_timer_struc;
   r3 = &$tws.local_volume_unmute;
   call $timer.schedule_event_in;


   r1 = &$tws.header_struc;
   M[$relay_struc+ $relay.TWS_HEADER_FIELD] = r1;


   call $block_interrupts;
   r3 = $music_example.VMMSG.VOLUME;
   call $message.unregister_handler;
   call $unblock_interrupts;


   r1 = &$M.music_example_message.volume_message_struc;
   r2 = $music_example.VMMSG.VOLUME;
   r3 = &$tws.volume_message_handler;
   call $message.register_handler;


   I0 = &$tws.message_volume_struc;
   r1 = M[$music_example.SystemVolume] ;
   M[I0,1] = r1;
   r1 = M[$music_example.MasterVolume] ;
   M[I0,1] = r1;
   r1 = M[$music_example.ToneVolume] ;
   M[I0,1] = r1;
   r1 = M[$music_example.LeftTrimVolume] ;
   M[I0,1] = r1;
   r1 = M[$music_example.RightTrimVolume] ;
   M[I0,1] = r1;

   r1 = &$tws.routing_mode_message_struc;
   r2 = $MESSAGE_VM_TWS_ROUTING_MODE;
   r3 = &$tws.routing_message_handler;
   call $message.register_handler;

   r1 = &$tws.device_trim_message_struc;
   r2 = $MESSAGE_VM_DEVICE_TRIMS;
   r3 = &$tws.device_trim_message_handler;
   call $message.register_handler;

   r1 = &$tws.external_volume_enable_message_struc;
   r2 = $MESSAGE_VM_EXTERNAL_VOLUME_ENABLE;
   r3 = &$tws.external_volume_enable_message_handler;
   call $message.register_handler;

   call $tws.configure_synchronised_warping;



   r3 = $CON_IN_PORT;
   call $cbuffer.is_it_enabled;
   if Z jump done;

   r2 = $MESSAGE_GET_BT_ADDRESS;
   call $message.send;

   done:
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 868 "relay_conn.asm"
.MODULE $M.relay.mode_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $relay.mode_message_handler:

   push rLink;


   push r1;

   M[$relay.mode] = r1;

   r6 = 20000;
   call $tws.soft_mute_handler;





   r1 = M[$relay.mode];
   null = r1 - $NO_RELAY_MODE;
   if Z jump relay_disable;

   null = r1 - $SHAREME_MODE;
   if Z jump shareme_enable;

   null = r1 - $TWS_MASTER_MODE;
   if Z jump tws_master_enable;
   null = r1 - $TWS_SLAVE_MODE;
   if Z jump tws_slave_enable;


   unsupported:

   pop r1;
   r1 = $ERR_UNSUPPORTED_MODE;
   push r1;
   r0 = $NO_RELAY_MODE;
   M[$relay.mode] = r0;


send_ack:
   r2 = $MESSAGE_VM_STREAM_RELAY_MODE_ACK;
   pop r3;
   call $message.send_short;
done:
   jump $pop_rLink_and_rts;

relay_disable:



   jump send_ack;

shareme_enable:




   jump unsupported;


tws_master_enable:





   jump unsupported;


tws_slave_enable:




   jump unsupported;


ack:
   push rLink;
   r1 = M[$relay.mode];
   push r1;
   jump send_ack;

.ENDMODULE;
.linefile 971 "relay_conn.asm"
.MODULE $M.relay.start;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $relay.start:
   push rLink;


   r0 = M[$relay.mode];
   null = r0 - $ERR_RELAY_LOST;
   if Z jump no_buffer_blocking;
   null = r0 - $NO_RELAY_MODE;
   if Z jump no_buffer_blocking;
   null = r0 - $TWS_SLAVE_MODE;
   if Z jump no_buffer_blocking;

   null = r0 - $TWS_MASTER_MODE;
   if NZ jump shareme;
.linefile 1012 "relay_conn.asm"
shareme:
   call $relay.update_internal_ptr;

no_buffer_blocking:
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1034 "relay_conn.asm"
.MODULE $M.relay.stop;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR relay_temp;

   $relay.stop:
   push rLink;

   M[relay_temp] = r5;



   r0 = M[$relay.mode];
   null = r0 - $ERR_RELAY_LOST;
   if Z jump check_update_ptr;
   null = r0 - $NO_RELAY_MODE;
   if Z jump check_update_ptr;
   null = r0 - $TWS_SLAVE_MODE;
   if NZ jump check_master_shareme;


   r1 = &$decoder_codec_stream_struc;
   r0 = M[r1 + $codec.av_decode.MODE_FIELD];
   Null = r0 - $codec.SUCCESS;
   if NZ jump check_update_ptr;
   call $tws.extract_header;
   if NZ jump schedule_output_frame;


   .VAR $bad_header_count = 0;
   r0 = M[$bad_header_count];
   r0 = r0 + 1;
   M[$bad_header_count] = r0;

   call $tws.bin_current_frame;

   jump done;

schedule_output_frame:
.linefile 1082 "relay_conn.asm"
   jump done;

check_master_shareme:
   r1 = &$decoder_codec_stream_struc;
   r2 = M[r1 + $codec.av_decode.MODE_FIELD];
   Null = r2 - $codec.SUCCESS;
   if NZ jump check_update_ptr;

   null = r0 - $SHAREME_MODE;
   if Z jump relay_only;
   null = r0 - $TWS_MASTER_MODE;
   if NZ jump check_update_ptr;

   null = M[$tws.master_enabled];
   if Z jump check_update_ptr;
   null = M[$tws.wallclock_running];
   if Z jump check_update_ptr;


   r2 = M[$tws.initial_holdoff];
   if Z jump initial_continue;
   r2 = r2 - 1;
   M[$tws.initial_holdoff]=r2;
   jump check_update_ptr;

   initial_continue:
.linefile 1118 "relay_conn.asm"
relay_only:
   r5 = M[relay_temp];
   call $relay.copy_data;

check_update_ptr:

   r0 = M[$relay.mode];
   null = r0 - $TWS_MASTER_MODE;
   if NZ jump skip_decode_cnt;
   r1 = M[$tws.decode_cnt];
   r1 = r1 + 1;
   r0 = 200;
   null = r1 - r0;
   if POS r1 = r0;
   M[$tws.decode_cnt] = r1;

   skip_decode_cnt:
   r0 = M[r5 + $relay.INTERNAL_CBUFFER_PTR_FIELD];
   call $cbuffer.get_write_address_and_size;
   if Z jump done;

   r5 = M[relay_temp];
   call $relay.update_codec_ptr;


   r1 = 0;
   r0 = M[r5 + $relay.INTERNAL_CBUFFER_PTR_FIELD];
   call $cbuffer.set_write_address;

   done:
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1170 "relay_conn.asm"
.MODULE $M.tws.synchronise_master;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.synchronise_master:

   push rLink;

   call $block_interrupts;

   call $tws.check_started_streaming;
   Null = M[$tws.started_streaming];
   if NZ call $tws.feed_dac_buffer;

   r7 = &$pcm_latency_input_struct;
   call $latency.calc_pcm_latency;
   r1 = $tws.wallclock_obj;
   call $wall_clock.get_time;
   r1 = r1 + r6;
   M[$tws.header_struc + $tws.header.PLAYBACK_TIME_FIELD] = r1;


   r0 = M[$tws.scheduled_sra];
   M[$tws.header_struc + $tws.header.SRA_TARGET_RATE_FIELD] = r0;
.linefile 1202 "relay_conn.asm"
   r0 = M[&$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD];
   M[$tws.header_struc + $tws.header.SRA_ACTUAL_RATE_FIELD]=r0;

   r3 = &$tws.message_volume_struc;
   r2 = length($tws.message_volume_struc);
   r1 = &$tws.header_struc + $tws.header.SYS_VOL_FIELD;
   call $tws.copy_array;


   r1 = M[&$tws.header_struc + $tws.header.TRIM_LEFT_FIELD];
   r0 = M[$tws.device_trim_slave];
   r1 = r1 + r0;
   M[ &$tws.header_struc + $tws.header.TRIM_LEFT_FIELD] = r1;

   r1 = M[&$tws.header_struc + $tws.header.TRIM_RIGHT_FIELD];
   r0 = M[$tws.device_trim_slave];
   r1 = r1 + r0;
   M[ &$tws.header_struc + $tws.header.TRIM_RIGHT_FIELD] = r1;

   r0 = M[$tws.message_routing_mode_slave];
   r0 = 0xff00ff AND r0;
   r0 = r0 OR $TWS_V3_PROTOCOL_ID;
   M[$tws.header_struc + $tws.header.ROUTING_MODE_FIELD]=r0;


   r1 = &$tws.set_synchronized_data_message_struc;
   null = M[r1 + $timer.ID_FIELD];
   if NZ jump do_not_set_timer;






   r0 = M[$sra_rate_addr];
   r0 = M[r0];


      M[$tws.header_struc + $tws.header.SRA_TARGET_RATE_FIELD] = r0;
      M[$tws.scheduled_sra] = r0;


      r3 = &$tws.message_volume_struc;
      r2 = length($tws.scheduled_volume_struc);
      r1 = &$tws.scheduled_volume_struc;
      call $tws.copy_array;


      r1 = M[&$tws.scheduled_volume_struc + 3];
      r0 = M[$tws.device_trim_master];
      r1 = r1 + r0;
      M[&$tws.scheduled_volume_struc + 3] = r1;

      r1 = M[&$tws.scheduled_volume_struc + 4];
      r0 = M[$tws.device_trim_master];
      r1 = r1 + r0;
      M[&$tws.scheduled_volume_struc + 4] = r1;

      r0 = M[$tws.message_routing_mode_master];
      M[$tws.scheduled_routing_mode] = r0;

      r0 = M[$tws.header_struc + $tws.header.ROUTING_MODE_FIELD];
      r0 = 0x000800 OR r0;
      M[$tws.header_struc + $tws.header.ROUTING_MODE_FIELD] = r0;

      r0 = M[$tws.header_struc + $tws.header.PLAYBACK_TIME_FIELD];
      r1 = M[$tws.wallclock_obj + $wall_clock.ADJUSTMENT_VALUE_FIELD];
      r2 = r0 - r1;
      r1 = &$tws.set_synchronized_data_message_struc;
      r3 = &$tws.set_synchronized_data_handler;
      call $timer.schedule_event_at;
      M[$tws.warp_timer_id] = r3;

   sample_rate_not_supported:
   do_not_set_timer:

   call $unblock_interrupts;
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1298 "relay_conn.asm"
.MODULE $M.tws.synchronise_slave;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.synchronise_slave:
   .VAR $tws.delay_intialized=0;


   push rLink;


      r7 = &$pcm_latency_input_struct;
      call $latency.calc_pcm_latency;

      r1 = $tws.wallclock_obj;
      call $wall_clock.get_time;
      .var $local_wallclock;
      M[$local_wallclock] = r1;
      r1 = r1 + r6;


      r0 = M[$tws.header_struc + $tws.header.PLAYBACK_TIME_FIELD];
.linefile 1330 "relay_conn.asm"
      r0 = r0 - r1;
      if NEG jump slave_will_play_later_than_master;


      Null = r0 - $TWS_SYNC_TOLERANCE;
      if NEG jump schedule_events;




   set_synchronisation_delay:
.linefile 1352 "relay_conn.asm"
      call $tws.local_volume_mute;
      call $tws.clear_input_audio;
      call $tws.feed_dac_buffer;


      r0 = M[$tws.header_struc + $tws.header.SRA_TARGET_RATE_FIELD ];
      M[$tws.synchronised_sra] = r0;
      r0 = M[$tws.header_struc + $tws.header.SRA_ACTUAL_RATE_FIELD];
      M[&$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD] = r0;
      M[&$audio_out_rate_adjustment_and_shift_op_mono.param + $cbops.rate_adjustment_and_shift.SRA_CURRENT_RATE_FIELD] = r0;


      r1 = &$tws.set_synchronized_data_message_struc;
      r2 = M[r1 + $timer.ID_FIELD];
      if NZ call $timer.cancel_event;




      r7 = &$pcm_latency_input_struct;
      call $latency.calc_pcm_latency;

      r1 = $tws.wallclock_obj;
      call $wall_clock.get_time;
      r1 = r1 + r6;





      r0 = M[$tws.header_struc + $tws.header.PLAYBACK_TIME_FIELD];
      r0 = r0 - r1;






      .VAR $bin_too_old = 0;

      Null = r0 - 10000;
      if GE jump sync_continue;
      r0 = M[$bin_too_old];
      r0 = r0 + 1;
      M[$bin_too_old] = r0;
      jump bin_frame;

      sync_continue:
      r1 = M[$current_codec_sampling_rate];
      Null = r1 - 48000;
      if NZ jump check_44100;
      r1 = 0.048;
      jump calculate_delay;

   check_44100:
      Null = r1 - 44100;
      if NZ jump check_32000;
      r1 = 0.0441;
      jump calculate_delay;

   check_32000:
      Null = r1 - 32000;
      if NZ jump check_16000;
      r1 = 0.032;
      jump calculate_delay;

   check_16000:
      Null = r1 - 16000;
      if NZ jump sample_rate_not_supported;
      r1 = 0.016;

   calculate_delay:
      r1 = r0 * r1 (frac);
      r0 = M[$tws.header_struc + $tws.header.SRA_ACTUAL_RATE_FIELD];
      r2 = r1 * r0 (frac);
      r1 = r1 - r2;

      r0 = LENGTH($M.system_config.data.delay_buf_left);
      Null = r0 - r1;
      if NEG jump bin_frame;

      M[$M.system_config.data.delay_left + $audio_proc.delay.DELAY_FIELD] = r1;
      M[$M.system_config.data.delay_right + $audio_proc.delay.DELAY_FIELD] = r1;
      M[$M.main.samples_latency_measure + 0] = r1;
      r1 = 1;
      M[$tws.delay_intialized] = r1;
      r2 = $TWS_SOFTMUTE_TIME;
      r1 = &$tws.softmute_data_timer_struc;
      r3 = &$tws.local_volume_unmute;
      call $timer.schedule_event_in;


      r7 = &$pcm_latency_input_struct;
      call $latency.calc_pcm_latency;

      r1 = $tws.wallclock_obj;
      call $wall_clock.get_time;
      r1 = r1 + r6;


      r0 = M[$tws.header_struc + $tws.header.PLAYBACK_TIME_FIELD];
      r0 = r0 - r1;
   schedule_events:

     call $tws.calc_sra;


     r0 = M[$tws.header_struc + $tws.header.ROUTING_MODE_FIELD];
     r0 = 0x000800 AND r0;
     if Z jump do_not_set_timer;

         r1 = &$tws.set_synchronized_data_message_struc;
         r2 = M[r1 + $timer.ID_FIELD];
         if NZ call $timer.cancel_event;

         r0 = M[$tws.header_struc + $tws.header.ROUTING_MODE_FIELD];
         r1 = 0xff0000 AND r0;
         null = r1 - $TWS_V3_PROTOCOL_ID;
         if Z jump supported_tws_version;


         r2 = $MESSAGE_DSP_TWS_ERROR;
         r3 = $TWS_VERSION_UNSUPPORTED;
         r3 = r3 OR r1;
         call $message.send;

         jump do_not_set_timer;

supported_tws_version:
         r0 = 0x0000ff AND r0;
         M[$tws.scheduled_routing_mode] = r0;


         r0 = M[$tws.header_struc + $tws.header.SRA_TARGET_RATE_FIELD];
         M[$tws.scheduled_sra] = r0;


         r1 = &$tws.scheduled_volume_struc;
         r2 = 5;
         r3 = &$tws.header_struc + $tws.header.SYS_VOL_FIELD;
         call $tws.copy_array;

         r0 = M[$tws.header_struc + $tws.header.PLAYBACK_TIME_FIELD];
         r1 = M[$tws.wallclock_obj + $wall_clock.ADJUSTMENT_VALUE_FIELD];
         r2 = r0 - r1;

         r1 = &$tws.set_synchronized_data_message_struc;
         r3 = &$tws.set_synchronized_data_handler;
         call $timer.schedule_event_at;
         M[$tws.warp_timer_id] = r3;

   do_not_set_timer:
   sample_rate_not_supported:
   done_synchronise:
   jump $pop_rLink_and_rts;

   slave_will_play_later_than_master:

      Null = r0 + $TWS_SYNC_TOLERANCE;
      if POS jump schedule_events;
      jump set_synchronisation_delay;

   bin_frame:
   call $tws.bin_current_frame;
   jump done_synchronise;
   zero_frame:

   call $tws.zero_current_frame;
      jump done_synchronise;

.ENDMODULE;
.linefile 1535 "relay_conn.asm"
.MODULE $M.tws.sbc_encoder;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$tws.sbc_encoder:

push rLink;


   Null = M[$codec_reset_needed];
   if Z jump no_codec_reset;
      r5 = &$av_encoder_codec_stream_struc;
      r0 = M[r5 + $codec.stream_encode.RESET_ADDR_FIELD];

      r5 = r5 + $codec.av_encode.ENCODER_STRUC_FIELD;
      call r0;
      M[$codec_reset_needed] = null;

no_codec_reset:


   r5 = &$av_encoder_codec_stream_struc;
   call $codec.av_encode;




   r5 = &$av_encoder_codec_stream_struc;
   r0 = M[r5 + $codec.av_encode.MODE_FIELD];
   r0 = r0 - $codec.SUCCESS;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1585 "relay_conn.asm"
.MODULE $M.tws.extract_header;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR success = 0;

   .VAR struc_temp;

   $tws.extract_header:

   push rLink;


   M[success] = Null;


   r0 = M[r5 + $relay.INPUT_CBUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   r4 = r0 ASHIFT 1;


   r0 = M[r5 + $relay.INPUT_CBUFFER_FIELD];
   call $cbuffer.get_read_address_and_size;
   I0 = r0;
   L0 = r1;


   r7 = r0;


   r8 = M[r5 + $relay.CODEC_GET_BITPOS];
   r8 = M[r8];


   r3 = 0;
   findsyncloop:

    r4 = r4 - 1;
    if NEG jump buffer_underflow_occured;


      r0 = 8;
      push r3;
      r2 = M[r5 + $relay.CODEC_GETBITS];
      call r2;
      pop r3;
      r3 = r3 LSHIFT 8;
      r3 = r3 + r1;


      Null = r3 - 0x435352;
      if Z jump continue1;

 jump findsyncloop;

continue1:

   r1 = M[r5 + $relay.TWS_HEADER_FIELD];
   I6 = r1 + $tws.header.ROUTING_MODE_FIELD;

   r10 = M[r1 + $tws.header.SIZE_FIELD];
   r10 = r10 - 1;
   do readloop;

      r4 = r4 - 3;
      if NEG jump buffer_underflow_occured;


      r0 = 8;
      push r3;
      r2 = M[r5 + $relay.CODEC_GETBITS];
      call r2;
      pop r3;
      r3 = r3 LSHIFT 8;
      r3 = r3 + r1;

      push r3;
      r2 = M[r5 + $relay.CODEC_GETBITS];
      call r2;
      pop r3;
      r3 = r3 LSHIFT 8;
      r3 = r3 + r1;

      push r3;
      r2 = M[r5 + $relay.CODEC_GETBITS];
      call r2;
      pop r3;
      r3 = r3 LSHIFT 8;
      r3 = r3 + r1;
      M[I6,1] = r3;

   readloop:
      r0 = M[$relay_struc + $relay.IS_APTX_FIELD];
      if Z jump continue;
      r0 = M[I0,1];
      r0 = 16;
      r1 = M[r5 + $relay.CODEC_GET_BITPOS];
      M[r1] = r0;

continue:
   r1 = 1;
   M[success] = r1 ;
   jump done_getting_header;

buffer_underflow_occured:

   I0 = r7;
   r1 = M[r5 + $relay.CODEC_GET_BITPOS];
   M[r1] = r8;

   jump clean_up;

done_getting_header:
   r0 = M[r5 + $relay.INPUT_CBUFFER_FIELD];
   r1 = I0;
   call $cbuffer.set_read_address;

clean_up:
   L0 = 0;
   r0 = M[success];

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1722 "relay_conn.asm"
.MODULE $M.tws.local_volume_mute;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   $tws.local_volume_mute:
   push rLink;


   r0 = M[$tws.local_mute];
   if NZ jump done;


   I0 = &$tws.local_saved_volume_struc;
   r1 = M[$music_example.SystemVolume];
   M[I0,1] = r1;
   r1 = M[$music_example.MasterVolume];
   M[I0,1] = r1;
   r1 = M[$music_example.ToneVolume];
   M[I0,1] = r1;
   r1 = M[$music_example.LeftTrimVolume];
   M[I0,1] = r1;
   r1 = M[$music_example.RightTrimVolume];
   M[I0,1] = r1;
   I0 = null;

   skip_save:

   r3 = &$tws.local_mute_volume_struc;
   call $M.music_example_message.Volume.func;
   r1 = 1;
   M[$tws.local_mute] = r1;
done:
   jump $pop_rLink_and_rts;
.ENDMODULE;
.linefile 1768 "relay_conn.asm"
.MODULE $M.tws.local_volume_unmute;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   $tws.local_volume_unmute:
   push rLink;
   r0 = M[$tws.local_mute];
   if Z jump done;
   M[$tws.local_mute] = Null;
   r3 = &$tws.local_saved_volume_struc;

   call $M.music_example_message.Volume.func;

done:
   jump $pop_rLink_and_rts;
.ENDMODULE;
.linefile 1804 "relay_conn.asm"
.MODULE $M.tws.volume_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.volume_message_handler:
   push rLink;


   r1 = &$tws.message_volume_struc;
   r2 = length($tws.message_volume_struc);
   call $tws.copy_array;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1835 "relay_conn.asm"
.MODULE $M.tws.device_trim_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.device_trim_message_handler:
   push rLink;

   M[$tws.device_trim_master] = r1;
   M[$tws.device_trim_slave] = r2;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1863 "relay_conn.asm"
.MODULE $M.tws.external_volume_enable_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.external_volume_enable_message_handler:
   push rLink;

   M[$tws.external_volume_enable] = r1;


   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1893 "relay_conn.asm"
.MODULE $M.tws.copy_array;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.copy_array:
   push rLink;


   I0 = r1;
   I1 = r3;
   r10 = r2;
   do copy_loop;
      r0 = M[I1,1];
      M[I0,1] = r0;
   copy_loop:

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1928 "relay_conn.asm"
.MODULE $M.tws.routing_message_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   .VAR $set_soft_mute;

   $tws.routing_message_handler:
   push rLink;

   M[$tws.message_routing_mode_master] = r1;
   M[$tws.message_routing_mode_slave] = r2;

   r1 = -1;
   M[$set_soft_mute] = r1;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 1961 "relay_conn.asm"
.MODULE $M.tws.soft_mute_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.soft_mute_handler:
   push rLink;


   r1 = -1;
   M[$audio_mute_op_stereo.param + $cbops.soft_mute_op.MUTE_DIRECTION] = r1;


   r1 = &$soft_mute_timer_struc;
   r2 = M[r1 + $timer.ID_FIELD];
   if NZ call $timer.cancel_event;


   r1 = $soft_mute_timer_struc;
   r2 = r6;
   r3 = $tws.soft_unmute_handler;
   call $timer.schedule_event_in;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2000 "relay_conn.asm"
.MODULE $M.tws.soft_unmute_handler;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.soft_unmute_handler:
   push rLink;


   r1 = 1;
   M[$audio_mute_op_stereo.param + $cbops.soft_mute_op.MUTE_DIRECTION] = r1;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2100 "relay_conn.asm"
.MODULE $M.tws.configure_synchronised_warping;
   .CODESEGMENT PM;

   $tws.configure_synchronised_warping:


   r0 = M[$sra_rate_addr];
   r0 = M[r0];
   M[$tws.synchronised_sra] = r0;


   r0 = &$tws.synchronised_sra;


   M[$audio_out_rate_adjustment_and_shift_op_mono.param + $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD] = r0;
   M[$audio_out_rate_adjustment_and_shift_op_stereo.param + $cbops.rate_adjustment_and_shift.SRA_TARGET_RATE_ADDR_FIELD] = r0;


   rts;

.ENDMODULE;



.MODULE $M.tws.set_synchronized_data_handler;

    .CODESEGMENT PM;
    .DATASEGMENT DM;

    $tws.set_synchronized_data_handler:

    push rLink;

    M[$tws.warp_timer_id] = Null;




   r1 = M[$tws.scheduled_routing_mode];
   r0 = M[$tws.routing_mode];
   r0 = r0 - r1;
   if Z jump no_mute_needed;

   r6 = 300000;
   call $tws.soft_mute_handler;

   no_mute_needed:

    r0 = M[$tws.scheduled_sra];
    r1 = M[$relay.mode];
    null = r1 - $TWS_MASTER_MODE;
    if Z jump no_extra_warp_required;
       r1 = M[$tws.slave_sra];
       r0 = r1 + r0;
    no_extra_warp_required:
    M[$tws.synchronised_sra] = r0;


    r0 = M[$tws.external_volume_enable];
    if Z jump digital_vol;

    r3 = $MESSAGE_DSP_VOLUME;
    r4 = $TWS_VOL_MESSAGE_SIZE;
    r5 = &$tws.scheduled_volume_struc;
    jump schedule_routing;

digital_vol:
    r0 = M[$tws.local_mute];
    if NZ jump update_saved_vol;
    r3 = &$tws.scheduled_volume_struc;
    call $M.music_example_message.Volume.func;
    jump schedule_routing;
update_saved_vol:
   r3 = &$tws.scheduled_volume_struc;
   r2 = length($tws.local_saved_volume_struc);
   r1 = &$tws.local_saved_volume_struc;
   call $tws.copy_array;

schedule_routing:
    r0 = M[$tws.scheduled_routing_mode];

    M[$tws.routing_mode] = r0;


    jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2206 "relay_conn.asm"
   .MODULE $M.tws.feed_dac_buffer;

   .CODESEGMENT PM;

   $tws.feed_dac_buffer:

   push rLink;

   call $block_interrupts;
   r0 = $dac_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   Null = r0 - M[$music_example.frame_processing_size];
   if POS jump done;

   r1 = M[$tws.insertion_counter];
   r1 = r1 + 1;
   M[$tws.insertion_counter] = r1;

   r0 = $dac_out_left_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;

   r0 = $dac_out_right_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I4 = r0;
   L4 = r1;

   r1 = 0;
   r10 = M[$music_example.frame_processing_size];
   do insert_frame_of_zeros;
      M[I0,1] = r1, M[I4,1] = r1;
   insert_frame_of_zeros:

   r0 = $dac_out_left_cbuffer_struc;
   r1 = I0;
   call $cbuffer.set_write_address;

   r0 = $dac_out_right_cbuffer_struc;
   r1 = I4;
   call $cbuffer.set_write_address;

   L0 = Null;
   L4 = Null;

   M[$tws.started_streaming] = Null;

   done:
   call $unblock_interrupts;
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2278 "relay_conn.asm"
.MODULE $M.tws.roleswitch_detect;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

$tws.roleswitch_detect:
   .VAR last_timer_time;
   .VAR last_adjustment;
   .VAR count;
   .VAR $curr_role = $UNKNOWN;

   push rLink;
   r1=1;
   M[$tws.wallclock_running] = r1;

   r0 = M[$TIMER_TIME];
   r5 = M[last_adjustment];
   M[last_adjustment] = r2;
   r3 = r2 - r5;
   null = r3 - 100;
   if GT jump role_switch_log;
   null = r3 + 100;
   if LT jump role_switch_log;

   null = 0 - r3;
   if NZ jump set_slave;
   r1 = M[count];
   r1 = r1 + 1;
   null = r1 - $ROLE_TIMEOUT;
   if LT jump done;
   r2 = $MASTER;
   M[$curr_role] = r2;
   r1 = null;
   jump done;

set_slave:
   r2 = $SLAVE;
   M[$curr_role] = r2;
   r1 = null;

done:
   M[count] = r1;
   jump $pop_rLink_and_rts;

role_switch_log:
   .VAR $role_reversal_detected = 0;
   r1 = M[$role_reversal_detected];
   r1 = r1 + 1;
   M[$role_reversal_detected] = r1;

   jump done;

.ENDMODULE;
.linefile 2345 "relay_conn.asm"
.MODULE $M.tws.reset;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.reset:

   push rLink;



   call $tws.disable;

   M[$tws.wired_mode_enabled] = null;
   M[$tws.master_enabled] = null;
   M[$M.system_config.data.delay_left + $audio_proc.delay.DELAY_FIELD] = null;
   M[$M.system_config.data.delay_right + $audio_proc.delay.DELAY_FIELD] = null;
   M[$M.main.samples_latency_measure + 0] = null;


   r4 = &$M.system_config.data.reinitialize_table;
   call $frame_sync.run_function_table;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2386 "relay_conn.asm"
.MODULE $M.tws.check_started_streaming;
   .CODESEGMENT PM;

   $tws.check_started_streaming:

   push rLink;
   r0 = &$dac_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r4 = r0;

   r0 = &$dac_out_temp_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   r4 = r4 + r0;

   null = r4 - 75;
   if POS jump done;

   r0 = &$audio_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_data;
   null = r0 - $music_example.NUM_SAMPLES_PER_FRAME;
   if POS jump done;

   r4 = 1;
   M[$tws.started_streaming] = r4;

   r1 = M[$tws.started_streaming_counter];
   r1 = r1 + 1;
   M[$tws.started_streaming_counter] = r1;

   done:
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2433 "relay_conn.asm"
.MODULE $M.tws.calc_sra;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.calc_sra:

   push rLink;






   r3 = M[$tws.average_playback_difference];
   r8 = M[$tws.alpha];
   r1 = 1.0 - r8;
   rMAC = r8 * r0;
   rMAC = rMAC + r1 * r3;
   r3 = rMAC;
   M[$tws.average_playback_difference] = r3;

   .var last_timer_time = 0;
   r1 = M[last_timer_time];
   if Z jump reset;

   r2 = r1 - M[$TIMER_TIME];
   null = r2 - 4000000;
   if neg jump done;


   r4 = M[$tws.average_playback_difference_old];
   r1 = r3 - r4;
   M[$tws.average_playback_difference_old] = r3;
   M[$tws.average_playback_difference] = r0;

   rMAC = r1;
   r2 = r2 ASHIFT 1;
   div = rMAC/r2;
   r8 = DivResult;

   r2 = M[$tws.slave_sra];
   r2 = r2 - r8;


   null = r2 - 500;
   if POS jump clear;
   null = r2 + 500;
   if NEG jump clear;




   r1 = 1;
   null = r0;
   if NEG r1 = -r1;
   r2 = r2 + r1;



   M[$tws.slave_sra] = r2;


   jump reset;

   done:
   jump $pop_rLink_and_rts;

   reset:
   r1 = M[$TIMER_TIME];
   M[last_timer_time] = r1;
   jump done;

   clear:
   M[last_timer_time] = null;
   jump done;

.ENDMODULE;
.linefile 2527 "relay_conn.asm"
.MODULE $M.tws.clear_input_audio;
   .CODESEGMENT PM;

   $tws.clear_input_audio:

   push rLink;


   r6 = 20000;
   call $tws.soft_mute_handler;


   M[$M.system_config.data.delay_left + $audio_proc.delay.DELAY_FIELD] = NULL;
   M[$M.system_config.data.delay_right + $audio_proc.delay.DELAY_FIELD] = NULL;
   M[$M.main.samples_latency_measure + 0] = NULL;



   r3 = M[$decoder_codec_stream_struc + $codec.av_decode.DECODER_NUM_OUTPUT_SAMPLES_FIELD];


   r0 = &$audio_out_left_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   M0 = -r3;
   r0 = M[I0,M0];
   r1 = I0;
   r0 = &$audio_out_left_cbuffer_struc;
   call $cbuffer.set_read_address;


   r0 = &$audio_out_right_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   M0 = -r3;
   r0 = M[I0,M0];
   r1 = I0;
   r0 = &$audio_out_right_cbuffer_struc;
   call $cbuffer.set_read_address;

   L0 = 0;
   M0 = 0;


   r4 = &$M.system_config.data.reinitialize_table;
   call $frame_sync.run_function_table;

   M[$M.tws.calc_sra.last_timer_time] = null;

   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2600 "relay_conn.asm"
.MODULE $M.tws.bin_current_frame;
   .CODESEGMENT PM;
   .DATASEGMENT DM;

   $tws.bin_current_frame:

   push rLink;




   r3 = M[$decoder_codec_stream_struc + $codec.av_decode.DECODER_NUM_OUTPUT_SAMPLES_FIELD];


   r0 = &$audio_out_left_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   M0 = -r3;
   r0 = M[I0,M0];
   r1 = I0;
   r0 = &$audio_out_left_cbuffer_struc;
   call $cbuffer.set_write_address;


   r0 = &$audio_out_right_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   M0 = -r3;
   r0 = M[I0,M0];
   r1 = I0;
   r0 = &$audio_out_right_cbuffer_struc;
   call $cbuffer.set_write_address;

   L0 = 0;
   M0 = 0;
   jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 2654 "relay_conn.asm"
.MODULE $M.tws.zero_current_frame;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   $tws.zero_current_frame:
   push rLink;
.linefile 2672 "relay_conn.asm"
   r3 = M[$decoder_codec_stream_struc + $codec.av_decode.DECODER_NUM_OUTPUT_SAMPLES_FIELD];

   r0 = &$audio_out_left_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   M0 = -r3;
   r0 = 0;
   M[I0,M0] = r0;

   r0 = &$audio_out_right_cbuffer_struc;
   call $cbuffer.get_write_address_and_size;
   I0 = r0;
   L0 = r1;
   M0 = -r3;
   r0 = 0;
   M[I0,M0]= r0;
   L0 = 0;
   M0 = 0;
   jump $pop_rLink_and_rts;
.ENDMODULE;
.linefile 2706 "relay_conn.asm"
.MODULE $M.tws.force_steady_state;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   $tws.force_steady_state:
   push rLink;
   call $block_interrupts;






buffer_fill:

   r0 = $audio_out_left_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   I1 = r0;
   L1 = r1;
   r0 = $audio_out_right_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   I4 = r0;
   L4 = r1;
   r0 = $audio_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_space;

   r10 = r0 ASHIFT -1;
   r1 = 0;
   r4 = 0;
   do fill_output_cbuffer_loop_left;
      M[I1,-1] = r1;
      M[I4,-1] = r4;
   fill_output_cbuffer_loop_left:
   r0 = $audio_out_left_cbuffer_struc;
   r1 = I1;
   call $cbuffer.set_read_address;
   r0 = $audio_out_right_cbuffer_struc;
   r1 = I4;
   call $cbuffer.set_read_address;
   L1 = 0;
   L4 = 0;

   r0 = $dac_out_temp_left_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   I1 = r0;
   L1 = r1;
   r0 = $dac_out_temp_right_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   I4 = r0;
   L4 = r1;
   r0 = $dac_out_temp_left_cbuffer_struc;
   call $cbuffer.calc_amount_space;

   r10 = r0;
   r1 = 0;
   r4 = 0;
   do fill_dac_out_cbuffer_loop_left;
      M[I1,-1] = r1;
      M[I4,-1] = r4;
   fill_dac_out_cbuffer_loop_left:
   r0 = $dac_out_temp_left_cbuffer_struc;
   r1 = I1;
   call $cbuffer.set_read_address;
   r0 = $dac_out_temp_right_cbuffer_struc;
   r1 = I4;
   call $cbuffer.set_read_address;
   L1 = 0;
   L4 = 0;

   r0 = $dac_out_left_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   I1 = r0;
   L1 = r1;
   r0 = $dac_out_right_cbuffer_struc;
   call $cbuffer.get_read_address_and_size;
   I4 = r0;
   L4 = r1;
   r0 = $dac_out_left_cbuffer_struc;
   call $cbuffer.calc_amount_space;

   r10 = r0;
   r1 = 0;
   r4 = 0;
   do fill_dac_cbuffer_loop_left;
      M[I1,-1] = r1;
      M[I4,-1] = r4;
   fill_dac_cbuffer_loop_left:
   r0 = $dac_out_left_cbuffer_struc;
   r1 = I1;
   call $cbuffer.set_read_address;
   r0 = $dac_out_right_cbuffer_struc;
   r1 = I4;
   call $cbuffer.set_read_address;
   L1 = 0;
   L4 = 0;

   r4 = &$M.system_config.data.reinitialize_table;
   call $frame_sync.run_function_table;
done_filling_output_buffer:
   call $unblock_interrupts;
   jump $pop_rLink_and_rts;
.ENDMODULE;
.linefile 2820 "relay_conn.asm"
.MODULE $M.tws.bin_headers;
   .CODESEGMENT PM;
   .DATASEGMENT DM;
   $tws.bin_headers:
   push rLink;
   call $block_interrupts;
   r0 = M[r5 + $codec.DECODER_IN_BUFFER_FIELD];
   call $cbuffer.calc_amount_data;
   null = r0 - 30;
   if NEG jump done_with_bin;
   M0 = 30;
   r0 = M[I0,M0];
   M0 = null;
done_with_bin:
   call $unblock_interrupts;
   pop rLink;
.ENDMODULE;
