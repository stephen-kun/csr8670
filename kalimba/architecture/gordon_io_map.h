#ifndef GORDON_IO_MAP_H_INCLUDED
#define GORDON_IO_MAP_H_INCLUDED

   // Memory map
   .CONST $INT_SW_ERROR_EVENT_TRIGGER          0xFFFE00; // RW   0 bits
   .CONST $INT_GBL_ENABLE                      0xFFFE11; // RW   1 bits
   .CONST $INT_ENABLE                          0xFFFE12; // RW   1 bits
   .CONST $INT_CLK_SWITCH_EN                   0xFFFE13; // RW   1 bits
   .CONST $INT_SOURCES_EN                      0xFFFE14; // RW  10 bits
   .CONST $INT_PRIORITIES                      0xFFFE15; // RW  20 bits
   .CONST $INT_LOAD_INFO                       0xFFFE16; // RW  15 bits
   .CONST $INT_ACK                             0xFFFE17; // RW   1 bits
   .CONST $INT_SOURCE                          0xFFFE18; //  R   6 bits
   .CONST $INT_SAVE_INFO                       0xFFFE19; //  R  15 bits
   .CONST $INT_ADDR                            0xFFFE1A; // RW  24 bits
   .CONST $DSP2MCU_EVENT_DATA                  0xFFFE1B; // RW  16 bits
   .CONST $PC_STATUS                           0xFFFE1C; //  R  24 bits
   .CONST $MCU2DSP_EVENT_DATA                  0xFFFE1D; //  R  16 bits
   .CONST $DOLOOP_CACHE_EN                     0xFFFE1E; // RW   1 bits
   .CONST $TIMER1_EN                           0xFFFE1F; // RW   1 bits
   .CONST $TIMER2_EN                           0xFFFE20; // RW   1 bits
   .CONST $TIMER1_TRIGGER                      0xFFFE21; // RW  24 bits
   .CONST $TIMER2_TRIGGER                      0xFFFE22; // RW  24 bits
   .CONST $WRITE_PORT0_DATA                    0xFFFE23; //  W  24 bits
   .CONST $WRITE_PORT1_DATA                    0xFFFE24; //  W  24 bits
   .CONST $WRITE_PORT2_DATA                    0xFFFE25; //  W  24 bits
   .CONST $WRITE_PORT3_DATA                    0xFFFE26; //  W  24 bits
   .CONST $WRITE_PORT4_DATA                    0xFFFE27; //  W  24 bits
   .CONST $WRITE_PORT5_DATA                    0xFFFE28; //  W  24 bits
   .CONST $WRITE_PORT6_DATA                    0xFFFE29; //  W  24 bits
   .CONST $WRITE_PORT7_DATA                    0xFFFE2A; //  W  24 bits
   .CONST $READ_PORT0_DATA                     0xFFFE2B; //  R  24 bits
   .CONST $READ_PORT1_DATA                     0xFFFE2C; //  R  24 bits
   .CONST $READ_PORT2_DATA                     0xFFFE2D; //  R  24 bits
   .CONST $READ_PORT3_DATA                     0xFFFE2E; //  R  24 bits
   .CONST $READ_PORT4_DATA                     0xFFFE2F; //  R  24 bits
   .CONST $READ_PORT5_DATA                     0xFFFE30; //  R  24 bits
   .CONST $READ_PORT6_DATA                     0xFFFE31; //  R  24 bits
   .CONST $READ_PORT7_DATA                     0xFFFE32; //  R  24 bits
   .CONST $PORT_BUFFER_SET                     0xFFFE33; // RW   0 bits
   .CONST $WRITE_PORT8_DATA                    0xFFFE34; //  W  24 bits
   .CONST $WRITE_PORT9_DATA                    0xFFFE35; //  W  24 bits
   .CONST $WRITE_PORT10_DATA                   0xFFFE36; //  W  24 bits
   .CONST $READ_PORT8_DATA                     0xFFFE38; //  R  24 bits
   .CONST $READ_PORT9_DATA                     0xFFFE39; //  R  24 bits
   .CONST $READ_PORT10_DATA                    0xFFFE3A; //  R  24 bits
   .CONST $MM_DOLOOP_START                     0xFFFE40; // RW  24 bits
   .CONST $MM_DOLOOP_END                       0xFFFE41; // RW  24 bits
   .CONST $MM_QUOTIENT                         0xFFFE42; // RW  24 bits
   .CONST $MM_REM                              0xFFFE43; // RW  24 bits
   .CONST $MM_RINTLINK                         0xFFFE44; // RW  24 bits
   .CONST $CLOCK_DIVIDE_RATE                   0xFFFE4D; // RW  16 bits
   .CONST $INT_CLOCK_DIVIDE_RATE               0xFFFE4E; // RW  16 bits
   .CONST $PIO_IN                              0xFFFE4F; //  R  24 bits
   .CONST $PIO2_IN                             0xFFFE50; //  R   8 bits
   .CONST $PIO_OUT                             0xFFFE51; // RW  24 bits
   .CONST $PIO2_OUT                            0xFFFE52; // RW   8 bits
   .CONST $PIO_DIR                             0xFFFE53; // RW  24 bits
   .CONST $PIO2_DIR                            0xFFFE54; // RW   8 bits
   .CONST $PIO_EVENT_EN_MASK                   0xFFFE55; // RW  24 bits
   .CONST $PIO2_EVENT_EN_MASK                  0xFFFE56; // RW   8 bits
   .CONST $INT_SW0_EVENT                       0xFFFE57; // RW   1 bits
   .CONST $INT_SW1_EVENT                       0xFFFE58; // RW   1 bits
   .CONST $INT_SW2_EVENT                       0xFFFE59; // RW   1 bits
   .CONST $INT_SW3_EVENT                       0xFFFE5A; // RW   1 bits
   .CONST $FLASH_WINDOW1_START_ADDR            0xFFFE5B; // RW  23 bits
   .CONST $FLASH_WINDOW2_START_ADDR            0xFFFE5C; // RW  23 bits
   .CONST $FLASH_WINDOW3_START_ADDR            0xFFFE5D; // RW  23 bits
   .CONST $NOSIGNX_MCUWIN1                     0xFFFE5F; // RW   1 bits
   .CONST $NOSIGNX_MCUWIN2                     0xFFFE60; // RW   1 bits
   .CONST $FLASHWIN1_CONFIG                    0xFFFE61; // RW   2 bits
   .CONST $FLASHWIN2_CONFIG                    0xFFFE62; // RW   2 bits
   .CONST $FLASHWIN3_CONFIG                    0xFFFE63; // RW   2 bits
   .CONST $NOSIGNX_PMWIN                       0xFFFE64; // RW   1 bits
   .CONST $PM_WIN_ENABLE                       0xFFFE65; // RW   1 bits
   .CONST $STACK_START_ADDR                    0xFFFE66; // RW  24 bits
   .CONST $STACK_END_ADDR                      0xFFFE67; // RW  24 bits
   .CONST $STACK_POINTER                       0xFFFE68; // RW  24 bits
   .CONST $STACK_OVERFLOW_PC                   0xFFFE69; //  R  24 bits
   .CONST $FRAME_POINTER                       0xFFFE6A; // RW  24 bits
   .CONST $NUM_RUN_CLKS_MS                     0xFFFE6B; // RW   8 bits
   .CONST $NUM_RUN_CLKS_LS                     0xFFFE6C; // RW  24 bits
   .CONST $NUM_INSTRS_MS                       0xFFFE6D; // RW   8 bits
   .CONST $NUM_INSTRS_LS                       0xFFFE6E; // RW  24 bits
   .CONST $NUM_STALLS_MS                       0xFFFE6F; // RW   8 bits
   .CONST $NUM_STALLS_LS                       0xFFFE70; // RW  24 bits
   .CONST $TIMER_TIME                          0xFFFE71; //  R  24 bits
   .CONST $TIMER_TIME_MS                       0xFFFE72; //  R   8 bits
   .CONST $WRITE_PORT0_CONFIG                  0xFFFE73; // RW   4 bits
   .CONST $WRITE_PORT1_CONFIG                  0xFFFE74; // RW   4 bits
   .CONST $WRITE_PORT2_CONFIG                  0xFFFE75; // RW   4 bits
   .CONST $WRITE_PORT3_CONFIG                  0xFFFE76; // RW   4 bits
   .CONST $WRITE_PORT4_CONFIG                  0xFFFE77; // RW   4 bits
   .CONST $WRITE_PORT5_CONFIG                  0xFFFE78; // RW   4 bits
   .CONST $WRITE_PORT6_CONFIG                  0xFFFE79; // RW   4 bits
   .CONST $WRITE_PORT7_CONFIG                  0xFFFE7A; // RW   4 bits
   .CONST $READ_PORT0_CONFIG                   0xFFFE7B; // RW   4 bits
   .CONST $READ_PORT1_CONFIG                   0xFFFE7C; // RW   4 bits
   .CONST $READ_PORT2_CONFIG                   0xFFFE7D; // RW   4 bits
   .CONST $READ_PORT3_CONFIG                   0xFFFE7E; // RW   4 bits
   .CONST $READ_PORT4_CONFIG                   0xFFFE7F; // RW   4 bits
   .CONST $READ_PORT5_CONFIG                   0xFFFE80; // RW   4 bits
   .CONST $READ_PORT6_CONFIG                   0xFFFE81; // RW   4 bits
   .CONST $READ_PORT7_CONFIG                   0xFFFE82; // RW   4 bits
   .CONST $PM_FLASHWIN_START_ADDR              0xFFFE83; // RW  23 bits
   .CONST $PM_FLASHWIN_SIZE                    0xFFFE84; // RW  24 bits
   .CONST $BITREVERSE_VAL                      0xFFFE89; // RW  24 bits
   .CONST $BITREVERSE_DATA                     0xFFFE8A; //  R  24 bits
   .CONST $BITREVERSE_DATA16                   0xFFFE8B; //  R  24 bits
   .CONST $BITREVERSE_ADDR                     0xFFFE8C; //  R  24 bits
   .CONST $ARITHMETIC_MODE                     0xFFFE93; // RW   5 bits
   .CONST $FORCE_FAST_MMU                      0xFFFE94; // RW   1 bits
   .CONST $DBG_COUNTERS_EN                     0xFFFE9F; // RW   1 bits
   .CONST $PM_FLASHWIN_CACHE_SIZE              0xFFFEE0; // RW   1 bits
   .CONST $WRITE_PORT8_CONFIG                  0xFFFEE1; // RW   4 bits
   .CONST $WRITE_PORT9_CONFIG                  0xFFFEE2; // RW   4 bits
   .CONST $WRITE_PORT10_CONFIG                 0xFFFEE3; // RW   4 bits
   .CONST $READ_PORT8_CONFIG                   0xFFFEE5; // RW   4 bits
   .CONST $READ_PORT9_CONFIG                   0xFFFEE6; // RW   4 bits
   .CONST $READ_PORT10_CONFIG                  0xFFFEE7; // RW   4 bits

   .CONST $READ_CONFIG_GAP                     $READ_PORT8_CONFIG - $READ_PORT7_CONFIG;
   .CONST $READ_DATA_GAP                       $READ_PORT8_DATA - $READ_PORT7_DATA;
   .CONST $WRITE_CONFIG_GAP                    $WRITE_PORT8_CONFIG - $WRITE_PORT7_CONFIG;
   .CONST $WRITE_DATA_GAP                      $WRITE_PORT8_DATA - $WRITE_PORT7_DATA;

    // Definitions for compatibility with existing code
   .CONST $INT_UNBLOCK                      $INT_ENABLE;

#endif

