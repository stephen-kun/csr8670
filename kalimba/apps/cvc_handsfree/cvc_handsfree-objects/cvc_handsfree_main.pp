.linefile 1 "cvc_handsfree_main.asm"
.linefile 1 "<command-line>"
.linefile 1 "cvc_handsfree_main.asm"
.linefile 31 "cvc_handsfree_main.asm"
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
.linefile 32 "cvc_handsfree_main.asm" 2
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
.linefile 33 "cvc_handsfree_main.asm" 2
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
.linefile 34 "cvc_handsfree_main.asm" 2
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
.linefile 35 "cvc_handsfree_main.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h"
.CONST $FRAMESYNCLIB_VERSION 0x000002;

.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h" 1
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/core_library.h" 1
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h" 2
.linefile 15 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_sidetone_mix_operator.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_sidetone_mix_operator.h"
   .CONST $frame_sync.sidetone_mix_op.INPUT_START_INDEX_FIELD 0;
   .CONST $frame_sync.sidetone_mix_op.OUTPUT_START_INDEX_FIELD 1;
   .CONST $frame_sync.sidetone_mix_op.SIDETONE_BUFFER_FIELD 2;
   .CONST $frame_sync.sidetone_mix_op.SIDETONE_MAX_SAMPLES_FIELD 3;
   .CONST $frame_sync.sidetone_mix_op.GAIN_FIELD 4;
   .CONST $frame_sync.sidetone_mix_op.TIMER_PERIOD_SAMPLES_FIELD 5;
   .CONST $frame_sync.sidetone_mix_op.AMOUNT_DATA_FIELD 6;
   .CONST $frame_sync.sidetone_mix_op.STRUC_SIZE 7;
.linefile 16 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_dac_sync_operator.h" 1
.linefile 11 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_dac_sync_operator.h"
.CONST $frame_sync.dac_wrap_op.INPUT_INDEX_FIELD 0;
.CONST $frame_sync.dac_wrap_op.LEFT_PORT_FIELD 1;
.CONST $frame_sync.dac_wrap_op.RIGHT_PORT_FIELD 2;
.CONST $frame_sync.dac_wrap_op.RATE_SCALE_FIELD 3;
.CONST $frame_sync.dac_wrap_op.BUFFER_ADJUST_FIELD 4;
.CONST $frame_sync.dac_wrap_op.MAX_ADVANCE_FIELD 5;
.CONST $frame_sync.dac_wrap_op.PTR_ADC_STATUS_FIELD 6;
.CONST $frame_sync.dac_wrap_op.PACKET_SIZE_PTR_FIELD 7;
.CONST $frame_sync.dac_wrap_op.COPY_LIMIT_PTR_FIELD 8;


.CONST $frame_sync.dac_wrap_op.DROP_INSERT_FIELD 9;
.CONST $frame_sync.dac_wrap_op.XFER_AMOUNT_FIELD 10;
.CONST $frame_sync.dac_wrap_op.CBUFFER_PTR_FIELD 11;
.CONST $frame_sync.dac_wrap_op.WRAP_COUNT_FIELD 12;
.CONST $frame_sync.dac_wrap_op.STRUC_SIZE 13;

.CONST $frame_sync.dac_sync_op.STRUC_PTR_FIELD 0;
.CONST $frame_sync.dac_sync_op.STRUC_SIZE 1;
.linefile 17 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_sco_copy_operator.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_sco_copy_operator.h"
   .CONST $frame_sync.sco_copy_op.INPUT_START_INDEX_FIELD 0;
   .CONST $frame_sync.sco_copy_op.OUTPUT_START_INDEX_FIELD 1;
   .CONST $frame_sync.sco_copy_op.SHIFT_AMOUNT_FIELD 2;

   .CONST $frame_sync.sco_copy_op.COPY_LIMIT_FIELD 3;

   .CONST $frame_sync.sco_copy_op.STRUC_SIZE 4;
.linefile 18 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h" 2
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
.linefile 19 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h" 2
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
.linefile 20 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_hw_warp_operator.h" 1
.linefile 14 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_hw_warp_operator.h"
.CONST $frame_sync.hw_warp_op.PORT_OFFSET 0;
.CONST $frame_sync.hw_warp_op.WHICH_PORTS_OFFSET 1;
.CONST $frame_sync.hw_warp_op.TARGET_RATE_OFFSET 2;
.CONST $frame_sync.hw_warp_op.PERIODS_PER_SECOND_OFFSET 3;
.CONST $frame_sync.hw_warp_op.COLLECT_SECONDS_OFFSET 4;
.CONST $frame_sync.hw_warp_op.ENABLE_DITHER_OFFSET 5;

.CONST $frame_sync.hw_warp_op.ACCUMULATOR_OFFSET 6;
.CONST $frame_sync.hw_warp_op.PERIOD_COUNTER_OFFSET 7;
.CONST $frame_sync.hw_warp_op.LAST_WARP_OFFSET 8;

.CONST $frame_sync.hw_warp_op.STRUC_SIZE 9;
.linefile 21 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_library.h" 2


.CONST $frame_sync.frame_process.AMT_RDY_BUFFER_PTR_FIELD 0;
.CONST $frame_sync.frame_process.MIN_AMOUNT_READY_FIELD 1;
.CONST $frame_sync.frame_process.NUM_OUTPUT_RATE_OBJECTS_FIELD 2;
.CONST $frame_sync.frame_process.NUM_RATE_OBJECTS_FIELD 3;
.CONST $frame_sync.frame_process.STRUC_SIZE 4;


.CONST $frame_sync.frame_process.FIRST_CBUFFER_STRUC_FIELD 4;
.linefile 36 "cvc_handsfree_main.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_stream_macros.h" 1
.linefile 37 "cvc_handsfree_main.asm" 2
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
.linefile 38 "cvc_handsfree_main.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/usbio.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/usbio.h"
.CONST $USB_STALL_CNT_THRESH 7;


.CONST $frame_sync.SYNC_MASK 0x7f;


.CONST $frame_sync.USB_IN_STEREO_COPY_SOURCE_FIELD 0;
.CONST $frame_sync.USB_IN_STEREO_COPY_LEFT_SINK_FIELD 1;
.CONST $frame_sync.USB_IN_STEREO_COPY_RIGHT_SINK_FIELD 2;
.CONST $frame_sync.USB_IN_STEREO_COPY_PACKET_LENGTH_FIELD 3;
.CONST $frame_sync.USB_IN_STEREO_COPY_SHIFT_AMOUNT_FIELD 4;
.CONST $frame_sync.USB_IN_STEREO_COPY_LAST_HEADER_FIELD 5;
.CONST $frame_sync.USB_IN_STEREO_PACKET_COUNT_MODULO_FIELD 6;
.CONST $frame_sync.USB_IN_STEREO_STATE_FIELD 7;
.CONST $frame_sync.USB_IN_STEREO_PACKET_COUNTER_FIELD 8;
.CONST $frame_sync.USB_IN_STEREO_COPY_RETRY_FIELD 9;
.CONST $frame_sync.USB_IN_STEREO_COPY_STRUC_SIZE 10;



.CONST $frame_sync.USB_IN_MONO_COPY_SOURCE_FIELD 0;
.CONST $frame_sync.USB_IN_MONO_COPY_SINK_FIELD 1;
.CONST $frame_sync.USB_IN_MONO_COPY_PACKET_LENGTH_FIELD 2;
.CONST $frame_sync.USB_IN_MONO_COPY_SHIFT_AMOUNT_FIELD 3;
.CONST $frame_sync.USB_IN_MONO_COPY_LAST_HEADER_FIELD 4;
.CONST $frame_sync.USB_IN_MONO_PACKET_COUNT_MODULO_FIELD 5;
.CONST $frame_sync.USB_IN_MONO_STATE_FIELD 6;
.CONST $frame_sync.USB_IN_MONO_PACKET_COUNTER_FIELD 7;
.CONST $frame_sync.USB_IN_MONO_COPY_RETRY_FIELD 8;
.CONST $frame_sync.USB_IN_MONO_COPY_STRUC_SIZE 9;



.CONST $frame_sync.USB_OUT_STEREO_LEFT_SOURCE_FIELD 0;
.CONST $frame_sync.USB_OUT_STEREO_RIGHT_SOURCE_FIELD 1;
.CONST $frame_sync.USB_OUT_STEREO_SINK_FIELD 2;
.CONST $frame_sync.USB_OUT_STEREO_SHIFT_AMOUNT_FIELD 3;
.CONST $frame_sync.USB_OUT_STEREO_TRANSFER_PER_PERIOD_FIELD 4;
.CONST $frame_sync.USB_OUT_STEREO_STALL_CNT_FIELD 5;
.CONST $frame_sync.USB_OUT_STEREO_STRUC_SIZE 6;



.CONST $frame_sync.USB_OUT_MONO_SOURCE_FIELD 0;
.CONST $frame_sync.USB_OUT_MONO_SINK_FIELD 1;
.CONST $frame_sync.USB_OUT_MONO_SHIFT_AMOUNT_FIELD 2;
.CONST $frame_sync.USB_OUT_MONO_TRANSFER_PER_PERIOD_FIELD 3;
.CONST $frame_sync.USB_OUT_MONO_STALL_CNT_FIELD 4;
.CONST $frame_sync.USB_OUT_MONO_STRUC_SIZE 5;

.CONST $frame_sync.IDLE_STATE 0;
.CONST $frame_sync.SYNCING_A_STATE 1;
.CONST $frame_sync.SYNCING_B_STATE 2;
.CONST $frame_sync.SYNCED_STATE 3;
.linefile 39 "cvc_handsfree_main.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/spi_comm_library.h" 1
.linefile 28 "C:/ADK3.5/kalimba/lib_sets/sdk/include/spi_comm_library.h"
.CONST $SPI_COMM_VERSION 0x010000;


.CONST $spi_comm.NEXT_ADDR_FIELD 0;
.CONST $spi_comm.ID_FIELD 1;
.CONST $spi_comm.HANDLER_ADDR_FIELD 2;
.CONST $spi_comm.STRUC_SIZE 3;
.linefile 40 "cvc_handsfree_main.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/plc100_library.h" 1
.linefile 22 "C:/ADK3.5/kalimba/lib_sets/sdk/include/plc100_library.h"
   .CONST $PLC100_VERSION 0x010000;
.linefile 31 "C:/ADK3.5/kalimba/lib_sets/sdk/include/plc100_library.h"
   .CONST $plc100.SPEECH_BUF_START_ADDR_FIELD 0;

   .CONST $plc100.SPEECH_BUF_PTR_FIELD 1;


   .CONST $plc100.OLA_BUF_PTR_FIELD 2;


   .CONST $plc100.OUTPUT_PTR_FIELD 3;


   .CONST $plc100.CONSTS_FIELD 4;


   .CONST $plc100.ATTENUATION_FIELD 5;


   .CONST $plc100.PER_THRESHOLD_FIELD 6;
   .CONST $plc100.PACKET_LEN_FIELD 7;
   .CONST $plc100.BFI_FIELD 8;
   .CONST $plc100.BFI1_FIELD 9;
   .CONST $plc100.BFI_CUR_FIELD 10;
   .CONST $plc100.PER_FIELD 11;
   .CONST $plc100.PITCH_FIELD 12;
   .CONST $plc100.BFI_PREV_FIELD 13;
   .CONST $plc100.HARM_FIELD 14;
   .CONST $plc100.TONALITY_FIELD 15;
   .CONST $plc100.LOOP_LIMIT_FIELD 16;
   .CONST $plc100.SUB_PACKET_LEN_FIELD 17;
   .CONST $plc100.LOOP_COUNTER_FIELD 18;

   .CONST $plc100.STRUC_SIZE 19;


   .CONST $plc100.consts.SPEECH_BUF_LEN_FIELD 0;
   .CONST $plc100.consts.OLA_LEN_FIELD 1;
   .CONST $plc100.consts.RANGE_FIELD 2;
   .CONST $plc100.consts.MIN_DELAY_FIELD 3;
   .CONST $plc100.consts.MAX_DELAY_FIELD 4;
   .CONST $plc100.consts.PER_TC_INV_FIELD 5;
   .CONST $plc100.consts.OLA_WIN_PTR_FIELD 6;
   .CONST $plc100.consts.STRUC_SIZE 7;






   .CONST $plc100.ONEQ16 0x010000;

   .CONST $plc100.M_THRESH 0x11EC;

   .CONST $plc100.HARM_TONETHRESH 0x1C000;
   .CONST $plc100.MAX_PACKET_LEN 60;
   .CONST $plc100.ATT_THRESH 0.95;

   .CONST $plc100.HARM_THRESHOLD 0xB333;
   .CONST $plc100.XCORR_THRESH 0x733333;


   .CONST $plc100.INITIAL_ATTENUATION 0.8;



   .CONST $plc100.BITERROR_PACKET 1;

   .CONST $plc100.MISSED_PACKET 3;





   .CONST $plc100.MIN_DELAY_NB 54;
   .CONST $plc100.MAX_DELAY_NB 108;
   .CONST $plc100.OLA_LEN_NB 10;
   .CONST $plc100.SP_BUF_LEN_NB 226;
   .CONST $plc100.RANGE_NB 4;
   .CONST $plc100.PER_TC_INV_NB 0x6666;

   .CONST $plc100.MIN_DELAY_WB 107;
   .CONST $plc100.MAX_DELAY_WB 214;
   .CONST $plc100.OLA_LEN_WB 24;
   .CONST $plc100.SP_BUF_LEN_WB 452;
   .CONST $plc100.RANGE_WB 8;
   .CONST $plc100.PER_TC_INV_WB 0x3333;
.linefile 41 "cvc_handsfree_main.asm" 2
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
.linefile 42 "cvc_handsfree_main.asm" 2
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
.linefile 43 "cvc_handsfree_main.asm" 2

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
.linefile 45 "cvc_handsfree_main.asm" 2
.linefile 1 "cvc_handsfree.h" 1
.linefile 12 "cvc_handsfree.h"
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_handsfree_config.h" 1
.linefile 13 "cvc_handsfree.h" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_handsfree_library_gen.h" 1
.linefile 12 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_handsfree_library_gen.h"
.CONST $CVC_HANDSFREE_SYSID 0xA00B;


.CONST $M.CVC_HANDSFREE.CONFIG.CNGENA 0x008000;
.CONST $M.CVC_HANDSFREE.CONFIG.RERENA 0x004000;
.CONST $M.CVC_HANDSFREE.CONFIG.PLCENA 0x002000;
.CONST $M.CVC_HANDSFREE.CONFIG.SNDAGCBYP 0x001000;
.CONST $M.CVC_HANDSFREE.CONFIG.BEXENA 0x000800;
.CONST $M.CVC_HANDSFREE.CONFIG.AEQBYP 0x000400;
.CONST $M.CVC_HANDSFREE.CONFIG.NDVCBYP 0x000200;
.CONST $M.CVC_HANDSFREE.CONFIG.RCVAGCBYP 0x000100;
.CONST $M.CVC_HANDSFREE.CONFIG.SND2OMSBYP 0x000080;
.CONST $M.CVC_HANDSFREE.CONFIG.RCVOMSBYP 0x000040;
.CONST $M.CVC_HANDSFREE.CONFIG.RERCBAENA 0x000020;
.CONST $M.CVC_HANDSFREE.CONFIG.WNRBYP 0x000008;
.CONST $M.CVC_HANDSFREE.CONFIG.BYPASS_AGCPERSIST 0x040000;


.CONST $M.CVC_HANDSFREE.STATUS.CUR_MODE_OFFSET 0;
.CONST $M.CVC_HANDSFREE.STATUS.CALL_STATE_OFFSET 1;
.CONST $M.CVC_HANDSFREE.STATUS.SYS_CONTROL_OFFSET 2;
.CONST $M.CVC_HANDSFREE.STATUS.CUR_DAC_OFFSET 3;
.CONST $M.CVC_HANDSFREE.STATUS.PRIM_PSKEY_OFFSET 4;
.CONST $M.CVC_HANDSFREE.STATUS.SEC_STAT_OFFSET 5;
.CONST $M.CVC_HANDSFREE.STATUS.PEAK_DAC_OFFSET 6;
.CONST $M.CVC_HANDSFREE.STATUS.PEAK_ADC_OFFSET 7;
.CONST $M.CVC_HANDSFREE.STATUS.PEAK_SCO_IN_OFFSET 8;
.CONST $M.CVC_HANDSFREE.STATUS.PEAK_SCO_OUT_OFFSET 9;
.CONST $M.CVC_HANDSFREE.STATUS.PEAK_MIPS_OFFSET 10;
.CONST $M.CVC_HANDSFREE.STATUS.NDVC_NOISE_EST_OFFSET 11;
.CONST $M.CVC_HANDSFREE.STATUS.NDVC_DAC_ADJ_OFFSET 12;
.CONST $M.CVC_HANDSFREE.STATUS.PEAK_AUX_OFFSET 13;
.CONST $M.CVC_HANDSFREE.STATUS.COMPILED_CONFIG 14;
.CONST $M.CVC_HANDSFREE.STATUS.VOLUME 15;
.CONST $M.CVC_HANDSFREE.STATUS.CONNSTAT 16;
.CONST $M.CVC_HANDSFREE.STATUS.PLC_PACKET_LOSS 17;
.CONST $M.CVC_HANDSFREE.STATUS.AEQ_GAIN_LOW 18;
.CONST $M.CVC_HANDSFREE.STATUS.AEQ_GAIN_HIGH 19;
.CONST $M.CVC_HANDSFREE.STATUS.AEQ_STATE 20;
.CONST $M.CVC_HANDSFREE.STATUS.AEQ_POWER_TEST 21;
.CONST $M.CVC_HANDSFREE.STATUS.AEQ_TONE_POWER 22;
.CONST $M.CVC_HANDSFREE.STATUS.NLP_TIER_HC_ACTIVE 23;
.CONST $M.CVC_HANDSFREE.STATUS.AEC_COUPLING_OFFSET 24;
.CONST $M.CVC_HANDSFREE.STATUS.VAD_RCV_DET_OFFSET 25;
.CONST $M.CVC_HANDSFREE.STATUS.SND_AGC_SPEECH_LVL 26;
.CONST $M.CVC_HANDSFREE.STATUS.SND_AGC_GAIN 27;
.CONST $M.CVC_HANDSFREE.STATUS.RCV_AGC_SPEECH_LVL 28;
.CONST $M.CVC_HANDSFREE.STATUS.RCV_AGC_GAIN 29;
.CONST $M.CVC_HANDSFREE.STATUS.WNR_PWR_LVL 30;
.CONST $M.CVC_HANDSFREE.STATUS.INTERFACE_TYPE 31;
.CONST $M.CVC_HANDSFREE.STATUS.INPUT_RATE 32;
.CONST $M.CVC_HANDSFREE.STATUS.OUTPUT_RATE 33;
.CONST $M.CVC_HANDSFREE.STATUS.CODEC_RATE 34;
.CONST $M.CVC_HANDSFREE.STATUS.BLOCK_SIZE 35;


.CONST $M.CVC_HANDSFREE.SYSMODE.STANDBY 0;
.CONST $M.CVC_HANDSFREE.SYSMODE.HFK 1;
.CONST $M.CVC_HANDSFREE.SYSMODE.SSR 2;
.CONST $M.CVC_HANDSFREE.SYSMODE.PSTHRGH 3;
.CONST $M.CVC_HANDSFREE.SYSMODE.LPBACK 4;
.CONST $M.CVC_HANDSFREE.SYSMODE.MAX_MODES 6;


.CONST $M.CVC_HANDSFREE.CALLST.UNKNOWN 0;
.CONST $M.CVC_HANDSFREE.CALLST.CONNECTED 1;
.CONST $M.CVC_HANDSFREE.CALLST.CONNECTING 2;
.CONST $M.CVC_HANDSFREE.CALLST.MUTE 3;


.CONST $M.CVC_HANDSFREE.CONTROL.DAC_OVERRIDE 0x8000;
.CONST $M.CVC_HANDSFREE.CONTROL.CALLSTATE_OVERRIDE 0x4000;
.CONST $M.CVC_HANDSFREE.CONTROL.MODE_OVERRIDE 0x2000;
.linefile 93 "C:/ADK3.5/kalimba/lib_sets/sdk/include/cvc_handsfree_library_gen.h"
.CONST $M.CVC_HANDSFREE.INTERFACE.ANALOG 0;
.CONST $M.CVC_HANDSFREE.INTERFACE.I2S 1;


.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_HFK_CONFIG 0;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_HFK_OMS_AGGR 1;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SSR_OMS_AGGR 2;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_OMS_HARMONICITY 3;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_WNR_AGGR 4;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_WNR_POWER_THRES 5;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_WNR_HOLD 6;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_CNG_Q 7;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_CNG_SHAPE 8;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DTC_AGGR 9;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RER_AGGRESSIVENESS 10;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RER_WGT_SY 11;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RER_OFFSET_SY 12;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RER_POWER 13;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RER_VAR_THRESH 14;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RERDT_OFF_THRESHOLD 15;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RERDT_AGGRESSIVENESS 16;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RERDT_POWER 17;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_MAX_LPWRX_MARGIN 18;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEC_REF_LPWR_HB 19;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_ADCGAIN 20;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_NDVC_HYSTERESIS 21;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_NDVC_ATK_TC 22;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_NDVC_DEC_TC 23;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_NDVC_NUMVOLSTEPS 24;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_NDVC_MAXNOISELVL 25;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_NDVC_MINNOISELVL 26;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_NDVC_LB 27;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_NDVC_HB 28;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_CONFIG 29;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_GAIN_EXP 30;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_GAIN_MANT 31;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B2 32;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B1 33;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE1_B0 34;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE1_A2 35;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE1_A1 36;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B2 37;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B1 38;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE2_B0 39;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE2_A2 40;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE2_A1 41;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B2 42;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B1 43;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE3_B0 44;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE3_A2 45;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE3_A1 46;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B2 47;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B1 48;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE4_B0 49;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE4_A2 50;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE4_A1 51;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B2 52;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B1 53;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE5_B0 54;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE5_A2 55;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_STAGE5_A1 56;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_SCALE1 57;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_SCALE2 58;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_SCALE3 59;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_SCALE4 60;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_PEQ_SCALE5 61;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_CONFIG 62;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_GAIN_EXP 63;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_GAIN_MANT 64;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE1_B2 65;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE1_B1 66;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE1_B0 67;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE1_A2 68;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE1_A1 69;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE2_B2 70;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE2_B1 71;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE2_B0 72;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE2_A2 73;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE2_A1 74;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE3_B2 75;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE3_B1 76;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE3_B0 77;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE3_A2 78;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE3_A1 79;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE4_B2 80;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE4_B1 81;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE4_B0 82;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE4_A2 83;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE4_A1 84;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE5_B2 85;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE5_B1 86;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE5_B0 87;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE5_A2 88;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_STAGE5_A1 89;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_SCALE1 90;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_SCALE2 91;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_SCALE3 92;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_SCALE4 93;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_PEQ_SCALE5 94;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE 95;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE1 96;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE2 97;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE3 98;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE4 99;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE5 100;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE6 101;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE7 102;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE8 103;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE9 104;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE10 105;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE11 106;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE12 107;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE13 108;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE14 109;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE15 110;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SIDETONE_GAIN 111;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_CLIP_POINT 112;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SIDETONE_LIMIT 113;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BOOST 114;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BOOST_CLIP_POINT 115;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_G_ALFA 116;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SNDGAIN_MANTISSA 117;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SNDGAIN_EXPONENT 118;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCVGAIN_MANTISSA 119;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCVGAIN_EXPONENT 120;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_PT_SNDGAIN_MANTISSA 121;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_PT_SNDGAIN_EXPONENT 122;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_PT_RCVGAIN_MANTISSA 123;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_PT_RCVGAIN_EXPONENT 124;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_REF_DELAY 125;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_ADCGAIN_SSR 126;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_ATTACK_TC 127;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_DECAY_TC 128;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_ENVELOPE_TC 129;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_INIT_FRAME_THRESH 130;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_RATIO 131;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_MIN_SIGNAL 132;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_MIN_MAX_ENVELOPE 133;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_DELTA_THRESHOLD 134;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_VAD_COUNT_THRESHOLD 135;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_G_INITIAL 136;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_TARGET 137;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_ATTACK_TC 138;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_DECAY_TC 139;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_A_90_PK 140;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_D_90_PK 141;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_G_MAX 142;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_START_COMP 143;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_COMP 144;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_INP_THRESH 145;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_SP_ATTACK 146;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_AD_THRESH1 147;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_AD_THRESH2 148;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_G_MIN 149;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SND_AGC_ECHO_HOLD_TIME 150;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_ATTACK_TC 151;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_DECAY_TC 152;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_ENVELOPE_TC 153;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_INIT_FRAME_THRESH 154;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_RATIO 155;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_MIN_SIGNAL 156;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_MIN_MAX_ENVELOPE 157;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_DELTA_THRESHOLD 158;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_VAD_COUNT_THRESHOLD 159;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_G_INITIAL 160;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_TARGET 161;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_ATTACK_TC 162;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_DECAY_TC 163;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_A_90_PK 164;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_D_90_PK 165;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_G_MAX 166;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_START_COMP 167;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_COMP 168;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_INP_THRESH 169;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_SP_ATTACK 170;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_AD_THRESH1 171;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_AD_THRESH2 172;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_AGC_G_MIN 173;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_ATK_TC 174;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_ATK_1MTC 175;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_DEC_TC 176;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_DEC_1MTC 177;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LO_GOAL_LOW 178;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LO_GOAL_MID 179;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LO_GOAL_HIGH 180;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_HI_GOAL_LOW 181;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_HI_GOAL_MID 182;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_HI_GOAL_HIGH 183;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_HI2_GOAL_LOW 184;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_HI2_GOAL_MID 185;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_HI2_GOAL_HIGH 186;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_TOTAL_ATT_LOW 187;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_TOTAL_ATT_MID 188;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_TOTAL_ATT_HIGH 189;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_NOISE_LVL_FLAGS 190;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_LOW_STEP 191;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_BEX_HIGH_STEP 192;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_POWER_TH 193;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_MIN_GAIN 194;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_MAX_GAIN 195;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_VOL_STEP_UP_TH1 196;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_VOL_STEP_UP_TH2 197;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LOW_STEP 198;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LOW_STEP_INV 199;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_HIGH_STEP 200;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_HIGH_STEP_INV 201;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LOW_BAND_INDEX 202;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LOW_BANDWIDTH 203;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LOG2_LOW_BANDWIDTH 204;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_MID_BANDWIDTH 205;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LOG2_MID_BANDWIDTH 206;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_HIGH_BANDWIDTH 207;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_LOG2_HIGH_BANDWIDTH 208;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_MID1_BAND_INDEX 209;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_MID2_BAND_INDEX 210;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AEQ_HIGH_BAND_INDEX 211;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_PLC_STAT_INTERVAL 212;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_RCV_OMS_HFK_AGGR 213;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_OMS_HI_RES_MODE 214;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_VSM_HB_TIER1 215;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_VSM_LB_TIER1 216;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_VSM_MAX_ATT_TIER1 217;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_HB_TIER1 218;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_LB_TIER1 219;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_MB_TIER1 220;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_NBINS_TIER1 221;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_ATT_TIER1 222;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_ATT_THRESH_TIER1 223;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_ECHO_THRESH_TIER1 224;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_TIER2_THRESH 225;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_VSM_HB_TIER2 226;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_VSM_LB_TIER2 227;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_VSM_MAX_ATT_TIER2 228;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_HB_TIER2 229;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_LB_TIER2 230;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_MB_TIER2 231;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_NBINS_TIER2 232;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_ATT_TIER2 233;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_ATT_THRESH_TIER2 234;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_FDNLP_ECHO_THRESH_TIER2 235;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_HD_THRESH_GAIN 236;


.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AUX_GAIN 237;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_SCO_STREAM_MIX 238;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_AUX_STREAM_MIX 239;

.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_0 240;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_1 241;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_2 242;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_3 243;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_4 244;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_5 245;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_6 246;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_7 247;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_8 248;
.CONST $M.CVC_HANDSFREE.PARAMETERS.OFFSET_DSP_USER_9 249;
.CONST $M.CVC_HANDSFREE.PARAMETERS.STRUCT_SIZE 250;
.linefile 14 "cvc_handsfree.h" 2
.linefile 25 "cvc_handsfree.h"
.CONST $CVC.TASK.OFFSET_SND_PROCESS 0;
.CONST $CVC.TASK.OFFSET_SND_PROCESS_TRIGGER 1;

.CONST $CVC.BW.PARAM.SYS_FS 0;
.CONST $CVC.BW.PARAM.Num_Samples_Per_Frame 1;
.CONST $CVC.BW.PARAM.Num_FFT_Freq_Bins 2;
.CONST $CVC.BW.PARAM.Num_FFT_Window 3;
.CONST $CVC.BW.PARAM.SND_PROCESS_TRIGGER 4;
.CONST $CVC.BW.PARAM.OMS_MODE_OBJECT 5;
.CONST $CVC.BW.PARAM.AEC_LPWRX_MARGIN_OVFL 6;
.CONST $CVC.BW.PARAM.AEC_LPWRX_MARGIN_SCL 7;
.CONST $CVC.BW.PARAM.AEC_PTR_NZ_TABLES 8;
.CONST $CVC.BW.PARAM.VAD_PEQ_PARAM_PTR 9;
.CONST $CVC.BW.PARAM.DCBLOC_PEQ_PARAM_PTR 10;
.CONST $CVC.BW.PARAM.FB_CONFIG_RCV_ANALYSIS 11;
.CONST $CVC.BW.PARAM.FB_CONFIG_RCV_SYNTHESIS 12;
.CONST $CVC.BW.PARAM.FB_CONFIG_AEC 13;
.CONST $CVC.BW.PARAM.BANDWIDTH_ID 14;

.CONST $M.CVC.vad_hold.PTR_VAD_FLAG_FIELD 0;
.CONST $M.CVC.vad_hold.PTR_ECHO_FLAG_FIELD 1;
.CONST $M.CVC.vad_hold.FLAG_FIELD 2;
.CONST $M.CVC.vad_hold.PTR_HOLD_TIME_FRAMES_FIELD 3;
.CONST $M.CVC.vad_hold.HOLD_COUNTDOWN_FIELD 4;
.CONST $M.CVC.vad_hold.STRUC_SIZE 5;
.linefile 192 "cvc_handsfree.h"
   .CONST $M.CVC.Num_FFT_Freq_Bins 129;
   .CONST $M.CVC.Num_Samples_Per_Frame 120;
   .CONST $M.CVC.Num_FFT_Window 240;

   .CONST $M.CVC.ADC_DAC_Num_Samples_Per_Frame $M.CVC.Num_Samples_Per_Frame;
   .CONST $M.CVC.ADC_DAC_Num_FFT_Freq_Bins $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.CVC.ADC_DAC_Num_SYNTHESIS_FB_HISTORY ($M.CVC.Num_FFT_Window + $M.CVC.Num_Samples_Per_Frame);

   .CONST $SAMPLE_RATE_ADC_DAC 16000;
   .CONST $BLOCK_SIZE_ADC_DAC 120;

   .CONST $SAMPLE_RATE 16000;
   .CONST $BLOCK_SIZE_SCO 120;

   .CONST $M.oms270.FFT_NUM_BIN $M.CVC.Num_FFT_Freq_Bins;
   .CONST $M.oms270.STATE_LENGTH $M.oms270.wide_band.STATE_LENGTH;
   .CONST $M.oms270.SCRATCH_LENGTH $M.oms270.wide_band.SCRATCH_LENGTH;

   .CONST $plc100.SP_BUF_LEN $plc100.SP_BUF_LEN_WB;
   .CONST $plc100.OLA_LEN $plc100.OLA_LEN_WB;
.linefile 46 "cvc_handsfree_main.asm" 2
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
.linefile 47 "cvc_handsfree_main.asm" 2
.linefile 1 "C:/ADK3.5/kalimba/lib_sets/sdk/include/frame_sync_tsksched.h" 1
.linefile 48 "cvc_handsfree_main.asm" 2





   .CONST $MESSAGE.AUDIO_CONFIG 0x2000;


   .CONST $TIMER_PERIOD_AUDIO_COPY_MICROS 625;


   .CONST $TIMER_PERIOD_PBLOCK_SEND_MICROS 3000*1000;

   .CONST $NUM_SAMPLES_2MS_16K (32);
.linefile 112 "cvc_handsfree_main.asm"
.CONST $CVC_HANDSFREE_SECID 0x310B;
.linefile 121 "cvc_handsfree_main.asm"
.MODULE $M.CVC.app.config;
   .DATASEGMENT DM;


   .VAR CVC_config_struct[$M.CVC.CONFIG.STRUC_SIZE] =
      &$App.Codec.Apply,
      &$CVC_AppHandleConfig,
      $M.hf.LoadPersistResp.func,
      $CVC_HANDSFREE_SECID,
      $CVC_VERSION,
      $M.CVC_HANDSFREE.SYSMODE.STANDBY,
      $M.CVC_HANDSFREE.SYSMODE.HFK,
     $M.CVC_HANDSFREE.SYSMODE.MAX_MODES,
      $M.CVC_HANDSFREE.CALLST.MUTE,
      $M.CVC_HANDSFREE.PARAMETERS.STRUCT_SIZE,
      &$M.CVC.data.CurParams,
      &$M.CVC.data.DefaultParameters_wb,
      $CVC_HANDSFREE_SYSID,
      $M.CVC.BANDWIDTH.WB_FS,
      &$set_variant_from_vm,
      &$M.CVC.data.StatisticsPtrs,
      &$dac_out.auxillary_mix_op.param,
      &$M.CVC.data.CurParams + $M.CVC_HANDSFREE.PARAMETERS.OFFSET_INV_DAC_GAIN_TABLE;
.ENDMODULE;
.linefile 156 "cvc_handsfree_main.asm"
.MODULE $M.CVC.app.scheduler;
   .DATASEGMENT DM;


    .VAR tasks[]=
        0,
        12,
        (Length(tasks) - $FRM_SCHEDULER.TASKS_FIELD)/2,
        0,
        0,
        0,
        0,
        0,
        0,

        $main_send, 7,
        $main_receive, 0,
        $main_housekeeping, 1;


.ENDMODULE;
.linefile 189 "cvc_handsfree_main.asm"
.MODULE $M.main;
   .CODESEGMENT MAIN_PM;

$main:

   call $stack.initialise;

   call $flash.init_dmconst;

   call $interrupt.initialise;

   call $message.initialise;

   call $pskey.initialise;

   call $cbuffer.initialise;

   call $Security.Initialize;

   call $spi_comm.initialize;

   call $audio_config.initialise;


   call $wall_clock.initialise;
   r8 = $sco_data.object;
   call $sco_timing.initialize;


   r8 = &$M.CVC.app.config.CVC_config_struct;
   call $CVC.PowerUpReset;
.linefile 228 "cvc_handsfree_main.asm"
   r2 = $MESSAGE_KALIMBA_READY;
   call $message.send_short;
.linefile 262 "cvc_handsfree_main.asm"
   call $CVC.Start;


   r1 = &$pblock_send_timer_struc;
   r2 = $TIMER_PERIOD_PBLOCK_SEND_MICROS;
   r3 = &$pblock_send_handler;
   call $timer.schedule_event_in;




main_loop:

    NULL = M[$M.audio_config.SysReConfigure];
    if NZ call $ConfigureSystem;


    Null = M[$M.CVC_SYS.AlgReInit];
    if NZ call $M.CVC_HANDSFREE.SystemReInitialize.func;

    r8 = &$M.CVC.app.scheduler.tasks;
    call $frame_sync.task_scheduler_run;
    jump main_loop;


$main_housekeeping:
      push rLink;


    call $spi_comm.polled_service_routine;


    r3 = M[$M.CVC_SYS.FrameCounter];
    r3 = r3 + 1;
    M[$M.CVC_SYS.FrameCounter] = r3;
.linefile 306 "cvc_handsfree_main.asm"
    r3 = M[$far_end.in.usb_copy_struc + $frame_sync.USB_IN_MONO_COPY_PACKET_LENGTH_FIELD];



    r2 = M[&$sco_data.object + $sco_pkt_handler.PACKET_IN_LEN_FIELD];
    null = M[$M.BackEnd.sco_streaming];
    if Z r2 = r3;
    r1 = M[$M.audio_config.encoding_config];
    r3 = -1;
    r0 = M[$M.audio_config.encoding_mode];
    if Z r2 = r2 LSHIFT r3;
    r1 = r1 LSHIFT 8;
    r0 = r0 OR r1;
    r1 = r2 LSHIFT 16;
    r0 = r0 OR r1;
    M[$M.CVC_SYS.ConnectStatus] = r0;



    r6 = M[&$M.CVC.data.ndvc_dm1 + $M.NDVC_Alg1_0_0.OFFSET_CURVOLLEVEL];
    call $CVC.VolumeControl.Set_DAC_Adjustment;



    jump $pop_rLink_and_rts;



$main_receive:
      push rLink;


      r7 = &$sco_data.object;
      null = M[$M.BackEnd.sco_streaming];
      if NZ call $frame_sync.sco_decode;


      r2 = &$M.CVC.data.ModeProcTableRcv;
      call $Security.ProcessFrame;

      jump $pop_rLink_and_rts;


$main_send:
      push rLink;


      r0 = M[$TIMER_TIME];
      push r0;



      r1 = M[$M.CVC_SYS.SysMode];
      M[$M.CVC_SYS.cur_mode] = r1;


      r2 = &$M.CVC.data.ModeProcTableSnd;
      call $Security.ProcessFrame;


      push r7;
      push r9;
      r9 = M[&$sco_data.object + $sco_pkt_handler.DECODER_PTR];
      r9 = M[r9 + $sco_decoder.DATA_PTR];
      r0 = M[$M.BackEnd.wbs_sco_encode_func];
      if NZ call r0;

      pop r9;
      pop r7;


      pop r0;
      r0 = r0 - M[$TIMER_TIME];
      r1 = M[$M.CVC.app.scheduler.tasks + $FRM_SCHEDULER.TOTALSND_FIELD];
      r1 = r1 - r0;
      M[$M.CVC.app.scheduler.tasks + $FRM_SCHEDULER.TOTALSND_FIELD]=r1;

      jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 404 "cvc_handsfree_main.asm"
.MODULE $M.audio_config;
   .CODESEGMENT AUDIO_CONFIG_PM;
   .DATASEGMENT DM;


   .VAR set_port_type_message_struc[$message.STRUC_SIZE];
   .VAR set_adcdac_rate_from_vm_message_struc[$message.STRUC_SIZE];
   .VAR set_tone_rate_from_vm_message_struc[$message.STRUC_SIZE];


   .VAR $audio_copy_timer_struc[$timer.STRUC_SIZE];


   .VAR encoding_mode = $FAR_END.AUDIO.SCO_SBC;
   .VAR encoding_config = 0;


   .VAR audio_if_mode = 0;
   .VAR audio_rate_matching = 0;


   .VAR adc_sampling_rate=0;
   .VAR dac_sampling_rate=0;




   .VAR SysReConfigure=1;

$audio_config.initialise:
   push rLink;



   r1 = &set_port_type_message_struc;
   r2 = $MESSAGE.AUDIO_CONFIG;
   r3 = &$set_backend_from_vm;
   call $message.register_handler;


   r1 = &set_adcdac_rate_from_vm_message_struc;
   r2 = 0x1070;
   r3 = &$set_front_end_from_vm;
   call $message.register_handler;


   r1 = &set_tone_rate_from_vm_message_struc;
   r2 = 0x1072;
   r3 = &$set_tone_rate_from_vm;
   call $message.register_handler;


   r1 = &$audio_copy_timer_struc;
   r2 = $TIMER_PERIOD_AUDIO_COPY_MICROS;
   r3 = &$audio_copy_handler;
   call $timer.schedule_event_in;


   r0 = $M.CVC.BANDWIDTH.WB;
   M[$M.CVC_SYS.cvc_bandwidth] = r0;


   call $ConfigureSystem;
   jump $pop_rLink_and_rts;
.linefile 484 "cvc_handsfree_main.asm"
$set_backend_from_vm:

   M[encoding_mode] = r1;
   M[encoding_config] = r2;

   jump Signal_system_reconfig;
.linefile 507 "cvc_handsfree_main.asm"
$set_front_end_from_vm:

   r1 = r1 AND 0xffff;
   r1 = r1 * 10 (int);
   M[adc_sampling_rate]=r1;
   M[dac_sampling_rate]=r1;


   r2 = r2 AND $SW_RATE_MATCH_MASK;
   M[audio_rate_matching] = r2;


   r3 = r3 AND $AUDIO_IF_MASK;
   M[audio_if_mode] = r3;


   jump Signal_system_reconfig;
.linefile 539 "cvc_handsfree_main.asm"
$set_variant_from_vm:

   r6 = &$M.CVC.data.DefaultParameters_nb;
   r5 = &$M.CVC.data.DefaultParameters_fe;
   r4 = &$M.CVC.data.DefaultParameters_wb;
   r9 = M[$M.CVC_SYS.cvc_bandwidth];
   Null = r9 - $M.CVC.BANDWIDTH.FE;
   if Z r6 = r5;
   Null = r9 - $M.CVC.BANDWIDTH.WB;
   if Z r6 = r4;
   M[&$M.CVC.app.config.CVC_config_struct + $M.CVC.CONFIG.DEF_PARAMS_PTR] = r6;

Signal_system_reconfig:
    r3 = 1;
    M[$M.audio_config.SysReConfigure]=r3;
    M[$M.CVC_SYS.AlgReInit]=r3;
    rts;
.linefile 564 "cvc_handsfree_main.asm"
$CVC_AppHandleConfig:

   r1 = M[$M.CVC_MODULES_STAMP.CompConfig];
   r1 = r1 AND (~(0x000004));
   r0 = r4 LSHIFT ( round(log2(0x000004)) - 1);
   r0 = r0 AND 0x000004;
   r1 = r1 OR r0;
   M[$M.CVC_MODULES_STAMP.CompConfig] = r1;
   rts;
.ENDMODULE;
.linefile 584 "cvc_handsfree_main.asm"
.MODULE $M.audio_copy_handler;
   .CODESEGMENT AUDIO_COPY_HANDLER_PM;
   .DATASEGMENT DM;

$audio_copy_handler:
   push rLink;


   r8 = &$adc_in.copy_struc;
   call $cbops_multirate.copy;


   call $DAC_CheckConnectivity;

   r8 = &$dac_out.copy_struc;
   call $cbops_multirate.copy;

   r8 = &$tone_in.copy_struc;
   call $cbops_multirate.copy;


   call $CVC.VolumeControl.Check_Aux_Volume;

   null = M[$M.BackEnd.sco_streaming];
   if NZ jump irq_sco;
irq_usb:


        r8 = &$far_end.in.usb_copy_struc;
        call $frame_sync.usb_in_mono_audio_copy;

        r8 = &$far_end.in.copy_struc;
        call $cbops_multirate.copy;


        r0 = $far_end.in.output.cbuffer_struc;
        r1 = M[$far_end.in.sw_rate_op.param + $cbops.rate_monitor_op.STALL_FIELD];
        null = r1 - $cbops.rate_monitor_op.NO_DATA_PERIODS_FOR_STALL;
        if POS call $cbuffer.empty_buffer;

        r8 = &$far_end.out.copy_struc;
        call $cbops_multirate.copy;


  r8 = &$far_end.out.usb_copy_struc;
        call $frame_sync.usb_out_mono_copy;


        r8 = &$M.CVC.app.scheduler.tasks;
        call $frame_sync.task_scheduler_isr;


        r1 = &$audio_copy_timer_struc;
        r2 = $TIMER_PERIOD_AUDIO_COPY_MICROS;
        r3 = &$audio_copy_handler;
        call $timer.schedule_event_in_period;
        jump $pop_rLink_and_rts;

irq_sco:

        r7 = &$M.CVC.app.scheduler.tasks + $FRM_SCHEDULER.COUNT_FIELD;
        r1 = &$audio_copy_timer_struc;
        r3 = &$audio_copy_handler;
        call $sco_timing.SyncClock;

     r8 = &$M.CVC.app.scheduler.tasks;
     call $frame_sync.task_scheduler_isr;

     jump $pop_rLink_and_rts;

.ENDMODULE;
.linefile 685 "cvc_handsfree_main.asm"
.MODULE $M.App.Codec.Apply;
   .CODESEGMENT CODEC_APPLY_PM;
   .DATASEGMENT DM;

$App.Codec.Apply:
   push rLink;


   r4 = M[$M.CVC.data.CurParams + $M.CVC_HANDSFREE.PARAMETERS.OFFSET_ADCGAIN];
   r0 = M[$M.CVC.data.CurParams + $M.CVC_HANDSFREE.PARAMETERS.OFFSET_ADCGAIN_SSR];
   r7 = M[$M.CVC_SYS.cur_mode];
   r7 = r7 - $M.CVC_HANDSFREE.SYSMODE.SSR;
   if Z r4 = r0;
.linefile 706 "cvc_handsfree_main.asm"
   r2 = $M.CVC.VMMSG.CODEC;
   call $message.send_short;
   jump $pop_rLink_and_rts;
.ENDMODULE;
.linefile 720 "cvc_handsfree_main.asm"
.MODULE $M.cvc.wbs_utility;
   .CODESEGMENT CVC_BANDWIDTH_PM;
   .DATASEGMENT DM;



$cvc.wb.wbs_initialize:
   push rLink;



   r5 = M[&$sco_data.object + $sco_pkt_handler.DECODER_PTR];
   push r5;

   r5 = r5 + ($sco_decoder.DATA_PTR - $codec.ENCODER_DATA_OBJECT_FIELD);
   call $sbcenc.init_static_encoder;

   pop r5;

   r5 = r5 + ($sco_decoder.DATA_PTR - $codec.DECODER_DATA_OBJECT_FIELD);
   call $sbcdec.init_static_decoder;

   jump $pop_rLink_and_rts;

$cvc.wb.wbs_sco_encode:
   jump $frame_sync.sco_encode;

.ENDMODULE;
.linefile 768 "cvc_handsfree_main.asm"
.MODULE $M.ConfigureSystem;
   .CODESEGMENT CVC_BANDWIDTH_PM;
   .DATASEGMENT DM;

   .VAR $cvc_fftbins = $M.CVC.Num_FFT_Freq_Bins;
   .VAR $fe_frame_resample_process = 0;
   .VAR $pblock_key = ($CVC_HANDSFREE_SYSID >> 8) | ($M.CVC.BANDWIDTH.WB_FS / 2000);

   .VAR Variant = $M.CVC.BANDWIDTH.WB;

   .VAR cvc_bandwidth_param_nb[] =
            $M.CVC.BANDWIDTH.NB_FS,
            60,
            65,
            120,
            8,
            &$M.oms270.mode.narrow_band.object,
            &$M.AEC_500_NB.LPwrX_margin.overflow_bits,
            &$M.AEC_500_NB.LPwrX_margin.scale_factor,
            &$M.AEC_500.nb_constants.nzShapeTables,

            &$M.CVC.data.vad_peq_parameters_nb,




            &$M.CVC.data.dcblock_parameters_nb,



            $filter_bank.config.frame60_proto120_fft128,
            $filter_bank.config.frame60_proto120_fft128,
            $filter_bank.config.frame60_proto240_fft128,
            0;

   .VAR cvc_bandwidth_param_fe[] =
            $M.CVC.BANDWIDTH.FE_FS,
            60,
            65,
            120,
            8,
            &$M.oms270.mode.narrow_band.object,
            &$M.AEC_500_NB.LPwrX_margin.overflow_bits,
            &$M.AEC_500_NB.LPwrX_margin.scale_factor,
            &$M.AEC_500.nb_constants.nzShapeTables,

            &$M.CVC.data.vad_peq_parameters_nb,




            &$M.CVC.data.dcblock_parameters_nb,



            $filter_bank.config.frame60_proto120_fft128,
            $filter_bank.config.frame120_proto240_fft256,
            $filter_bank.config.frame60_proto240_fft128,
            0;

   .VAR cvc_bandwidth_param_wb[] =
            $M.CVC.BANDWIDTH.WB_FS,
            120,
            129,
            240,
            7,
            &$M.oms270.mode.wide_band.object,
            &$M.AEC_500_WB.LPwrX_margin.overflow_bits,
            &$M.AEC_500_WB.LPwrX_margin.scale_factor,
            &$M.AEC_500.wb_constants.nzShapeTables,

            &$M.CVC.data.vad_peq_parameters_wb,




            &$M.CVC.data.dcblock_parameters_wb,



            $filter_bank.config.frame120_proto240_fft256,
            $filter_bank.config.frame120_proto240_fft256,
            $filter_bank.config.frame120_proto480_fft256,
            0;
.linefile 865 "cvc_handsfree_main.asm"
$ConfigureSystem:
   push rLink;

   M[$M.audio_config.SysReConfigure]=NULL;

   call $block_interrupts;
   call $ConfigureFrontEnd;
   r1 = M[$M.audio_config.encoding_mode];
   call $ConfigureBackEnd;
   call $unblock_interrupts;


   r6 = &cvc_bandwidth_param_nb;
   r5 = &cvc_bandwidth_param_fe;
   r4 = &cvc_bandwidth_param_wb;
   r9 = M[$M.CVC_SYS.cvc_bandwidth];
   M[Variant] = r9;
   Null = r9 - $M.CVC.BANDWIDTH.FE;
   if Z r6 = r5;
   Null = r9 - $M.CVC.BANDWIDTH.WB;
   if Z r6 = r4;


   r0 = M[r6 + $CVC.BW.PARAM.SYS_FS];
   M[&$M.CVC.app.config.CVC_config_struct + $M.CVC.CONFIG.SYS_FS] = r0;


   r1 = M[r6 + $CVC.BW.PARAM.Num_Samples_Per_Frame];




   r2 = M[$M.CVC.data.AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_HISTORY];
   r2 = r2 + r1;
   M[$M.CVC.data.oms270snd2_obj + $M.oms270.PTR_INP_X_FIELD] = r2;


   r2 = M[$M.CVC.data.AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CH1_PTR_HISTORY];
   r2 = r2 + r1;
   M[$M.CVC.data.oms270snd1_obj + $M.oms270.PTR_INP_X_FIELD] = r2;







   r1 = M[r6 + $CVC.BW.PARAM.Num_Samples_Per_Frame];
   r2 = M[$M.CVC.data.RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_PTR_HISTORY];
   r2 = r2 - r1;
   M[$M.CVC.data.oms270rcv_obj + $M.oms270.PTR_INP_X_FIELD] = r2;


   r0 = M[r6 + $CVC.BW.PARAM.Num_FFT_Freq_Bins];
   M[$cvc_fftbins] = r0;

   M[&$M.CVC.data.AEQ_DataObject + $M.AdapEq.NUM_FREQ_BINS] = r0;


   M[&$M.CVC.data.aec_dm1 + $M.AEC_500.OFFSET_NUM_FREQ_BINS] = r0;
   M[&$M.CVC.data.vsm_fdnlp_dm1 + $M.AEC_500_HF.OFFSET_NUM_FREQ_BINS] = r0;

   r0 = M[r6 + $CVC.BW.PARAM.Num_FFT_Window];

   M[&$M.CVC.data.oms270rcv_obj + $M.oms270.FFT_WINDOW_SIZE_FIELD] = r0;



   r0 = r0 + r0;


   M[&$M.CVC.data.oms270snd1_obj + $M.oms270.FFT_WINDOW_SIZE_FIELD] = r0;


   M[&$M.CVC.data.oms270snd2_obj + $M.oms270.FFT_WINDOW_SIZE_FIELD] = r0;





   r0 = M[r6 + $CVC.BW.PARAM.SND_PROCESS_TRIGGER];
   M[$M.CVC.app.scheduler.tasks + $FRM_SCHEDULER.TASKS_FIELD + $CVC.TASK.OFFSET_SND_PROCESS_TRIGGER]=r0;

   r0 = M[r6 + $CVC.BW.PARAM.OMS_MODE_OBJECT];

   M[&$M.CVC.data.oms270rcv_obj + $M.oms270.PTR_MODE_FIELD] = r0;


   M[&$M.CVC.data.oms270snd1_obj + $M.oms270.PTR_MODE_FIELD] = r0;


   M[&$M.CVC.data.oms270snd2_obj + $M.oms270.PTR_MODE_FIELD] = r0;





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
   M[&$M.CVC.data.sco_dc_block_dm1 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;
   M[&$M.CVC.data.adc_dc_block_dm1 + $audio_proc.peq.PARAM_PTR_FIELD] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.FB_CONFIG_RCV_ANALYSIS];
   M[&$M.CVC.data.RcvAnalysisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.FB_CONFIG_RCV_SYNTHESIS];
   M[&$M.CVC.data.RcvSynthesisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;

   r0 = M[r6 + $CVC.BW.PARAM.FB_CONFIG_AEC];
   M[&$M.CVC.data.AecAnalysisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;
   M[&$M.CVC.data.SndSynthesisBank + $M.filter_bank.Parameters.OFFSET_CONFIG_OBJECT] = r0;


   r0 = M[r6 + $CVC.BW.PARAM.BANDWIDTH_ID];
   r3 = r0 OR ($CVC_HANDSFREE_SYSID >> 8);
   M[$pblock_key] = r3;
   r2 = $M.CVC.VMMSG.LOADPERSIST;
   call $message.send_short;

   jump $pop_rLink_and_rts;

.ENDMODULE;
