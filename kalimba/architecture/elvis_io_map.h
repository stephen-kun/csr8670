// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change$  $DateTime$
// *****************************************************************************

#ifndef ELVIS_IO_MAP_H_INCLUDED
#define ELVIS_IO_MAP_H_INCLUDED
   // -- BC5-MM Kalimba Memory Mapped I/O Registers --
   // ------------------------------------------------

   // Interrupt controller setup registers
   .CONST $INT_SW_ERROR_EVENT_TRIGGER         0xFFFF00;  // RW   0 bits
   .CONST $INT_GBL_ENABLE                     0xFFFF01;  // RW   1 bits
   .CONST $INT_ENABLE                         0xFFFF02;  // RW   1 bits
   .CONST $INT_CLK_SWITCH_EN                  0xFFFF03;  // RW   1 bits
   .CONST $INT_SOURCES_EN                     0xFFFF04;  // RW   9 bits
   .CONST $INT_PRIORITIES                     0xFFFF05;  // RW  18 bits
   .CONST $INT_LOAD_INFO                      0xFFFF06;  // RW  14 bits
   .CONST $INT_ACK                            0xFFFF07;  // RW   1 bits
   .CONST $INT_SOURCE                         0xFFFF08;  // R    5 bits
   .CONST $INT_SAVE_INFO                      0xFFFF09;  // R   13 bits

    // Interrupt Events
   .CONST $DSP2MCU_EVENT_DATA                 0xFFFF0A;  // RW  16 bits
   .CONST $MCU2DSP_EVENT_DATA                 0xFFFF0B;  // R   16 bits
   .CONST $INT_SW0_EVENT                      0xFFFF32;  // RW   1 bits
   .CONST $INT_SW1_EVENT                      0xFFFF33;  // RW   1 bits
   .CONST $INT_SW2_EVENT                      0xFFFF34;  // RW   1 bits
   .CONST $INT_SW3_EVENT                      0xFFFF35;  // RW   1 bits

    // Timer
   .CONST $TIMER_TIME                         0xFFFF4A;  // R   24 bits
   .CONST $TIMER_TIME_MS                      0xFFFF4B;  // R   24 bits
   .CONST $TIMER1_EN                          0xFFFF0C;  // RW   1 bits
   .CONST $TIMER2_EN                          0xFFFF0D;  // RW   1 bits
   .CONST $TIMER1_TRIGGER                     0xFFFF0E;  // RW  24 bits
   .CONST $TIMER2_TRIGGER                     0xFFFF0F;  // RW  24 bits

    // MMU ports
   .CONST $WRITE_PORT0_DATA                   0xFFFF10;  // RW  24/16/8 bits
   .CONST $WRITE_PORT1_DATA                   0xFFFF11;  // RW  24/16/8 bits
   .CONST $WRITE_PORT2_DATA                   0xFFFF12;  // RW  24/16/8 bits
   .CONST $WRITE_PORT3_DATA                   0xFFFF13;  // RW  24/16/8 bits
   .CONST $WRITE_PORT4_DATA                   0xFFFF14;  // RW  24/16/8 bits
   .CONST $WRITE_PORT5_DATA                   0xFFFF15;  // RW  24/16/8 bits
   .CONST $WRITE_PORT6_DATA                   0xFFFF16;  // RW  24/16/8 bits
   .CONST $WRITE_PORT7_DATA                   0xFFFF17;  // RW  24/16/8 bits
   .CONST $READ_PORT0_DATA                    0xFFFF18;  // R   24/16/8 bits
   .CONST $READ_PORT1_DATA                    0xFFFF19;  // R   24/16/8 bits
   .CONST $READ_PORT2_DATA                    0xFFFF1A;  // R   24/16/8 bits
   .CONST $READ_PORT3_DATA                    0xFFFF1B;  // R   24/16/8 bits
   .CONST $READ_PORT4_DATA                    0xFFFF1C;  // R   24/16/8 bits
   .CONST $READ_PORT5_DATA                    0xFFFF1D;  // R   24/16/8 bits
   .CONST $READ_PORT6_DATA                    0xFFFF1E;  // R   24/16/8 bits
   .CONST $READ_PORT7_DATA                    0xFFFF1F;  // R   24/16/8 bits
   .CONST $WRITE_PORT0_CONFIG                 0xFFFF4C;  // RW   4 bits
   .CONST $WRITE_PORT1_CONFIG                 0xFFFF4D;  // RW   4 bits
   .CONST $WRITE_PORT2_CONFIG                 0xFFFF4E;  // RW   4 bits
   .CONST $WRITE_PORT3_CONFIG                 0xFFFF4F;  // RW   4 bits
   .CONST $WRITE_PORT4_CONFIG                 0xFFFF50;  // RW   4 bits
   .CONST $WRITE_PORT5_CONFIG                 0xFFFF51;  // RW   4 bits
   .CONST $WRITE_PORT6_CONFIG                 0xFFFF52;  // RW   4 bits
   .CONST $WRITE_PORT7_CONFIG                 0xFFFF53;  // RW   4 bits
   .CONST $READ_PORT0_CONFIG                  0xFFFF54;  // RW   4 bits
   .CONST $READ_PORT1_CONFIG                  0xFFFF55;  // RW   4 bits
   .CONST $READ_PORT2_CONFIG                  0xFFFF56;  // RW   4 bits
   .CONST $READ_PORT3_CONFIG                  0xFFFF57;  // RW   4 bits
   .CONST $READ_PORT4_CONFIG                  0xFFFF58;  // RW   4 bits
   .CONST $READ_PORT5_CONFIG                  0xFFFF59;  // RW   4 bits
   .CONST $READ_PORT6_CONFIG                  0xFFFF5A;  // RW   4 bits
   .CONST $READ_PORT7_CONFIG                  0xFFFF5B;  // RW   4 bits
   .CONST $PORT_BUFFER_SET                    0xFFFF20;  // RW   0 bits
   .CONST $READ_PORT_CONFIG_BASE              $READ_PORT0_CONFIG;
   .CONST $WRITE_PORT_CONFIG_BASE             $WRITE_PORT0_CONFIG;
   .CONST $READ_PORT_DATA_BASE                $READ_PORT0_DATA;
   .CONST $WRITE_PORT_DATA_BASE               $WRITE_PORT0_DATA;

   // Mem-mapped state registers
   .CONST $MM_DOLOOP_START                    0xFFFF21;  // RW  16 bits
   .CONST $MM_DOLOOP_END                      0xFFFF22;  // RW  16 bits
   .CONST $MM_QUOTIENT                        0xFFFF23;  // RW  24 bits
   .CONST $MM_REM                             0xFFFF24;  // RW  24 bits

   // Clock rate control
   .CONST $CLOCK_DIVIDE_RATE                  0xFFFF2D;  // RW   4 bits
   .CONST $INT_CLOCK_DIVIDE_RATE              0xFFFF2E;  // RW   4 bits

   // PIOs
   .CONST $PIO_IN                             0xFFFF2F;  // R   24 bits
   .CONST $PIO_OUT                            0xFFFF30;  // RW  24 bits
   .CONST $PIO_DIR                            0xFFFF66;  // RW  24 bits
   .CONST $PIO_EVENT_EN_MASK                  0xFFFF31;  // RW  24 bits

   // PM flash window configuration
   .CONST $PM_FLASHWIN_START_ADDR             0xFFFF5C;  // RW  24 bits
   .CONST $PM_FLASHWIN_SIZE                   0xFFFF5D;  // RW  24 bits

   // PM window control
   .CONST $PM_WIN_ENABLE                      0xFFFF40;  // RW   1 bits
   .CONST $NOSIGNX_PMWIN                      0xFFFF3F;  // RW   1 bits

   // Flash window control
   .CONST $FLASH_WINDOW1_START_ADDR           0xFFFF36;  // RW  24 bits
   .CONST $FLASH_WINDOW2_START_ADDR           0xFFFF37;  // RW  24 bits
   .CONST $FLASH_WINDOW3_START_ADDR           0xFFFF38;  // RW  24 bits
   .CONST $NOSIGNX_FLASHWIN1                  0xFFFF3C;  // RW   1 bits
   .CONST $NOSIGNX_FLASHWIN2                  0xFFFF3D;  // RW   1 bits
   .CONST $NOSIGNX_FLASHWIN3                  0xFFFF3E;  // RW   1 bits

   // MCU window control
   .CONST $NOSIGNX_MCUWIN1                    0xFFFF3A;  // RW   1 bits
   .CONST $NOSIGNX_MCUWIN2                    0xFFFF3B;  // RW   1 bits

   // Hardware stack setup
   .CONST $STACK_START_ADDR                   0xFFFF41;  // RW  16 bits
   .CONST $STACK_END_ADDR                     0xFFFF42;  // RW  16 bits
   .CONST $STACK_POINTER                      0xFFFF43;  // RW  16 bits

   // Profiling information registers
   .CONST $NUM_RUN_CLKS_MS                    0xFFFF44;  // RW   8 bits
   .CONST $NUM_RUN_CLKS_LS                    0xFFFF45;  // RW  24 bits
   .CONST $NUM_INSTRS_MS                      0xFFFF46;  // RW   8 bits
   .CONST $NUM_INSTRS_LS                      0xFFFF47;  // RW  24 bits
   .CONST $NUM_STALLS_MS                      0xFFFF48;  // RW   8 bits
   .CONST $NUM_STALLS_LS                      0xFFFF49;  // RW  24 bits

   // Bitreverse function
   .CONST $BITREVERSE_DATA                    0xFFFF62;  // RW  24 bits

   // ALU configurations
   .CONST $ARITHMETIC_MODE                    0xFFFF67;  // RW   1 bits

   // Fast MMU clock request
   .CONST $FORCE_FAST_MMU                     0xFFFF68;  // RW   1 bits

#endif
