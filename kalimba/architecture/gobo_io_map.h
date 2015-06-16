// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change$  $DateTime$
// *****************************************************************************

#ifndef GOBO_IO_MAP_H_INCLUDED
#define GOBO_IO_MAP_H_INCLUDED

   // -- Kalimba Memory Mapped I/O Registers --
   //Interrupt controller setup registers
   .CONST $INT_SW_ERR_EVENT_TRIGGER       0xFFFF00;  //  RW   0 bits
   .CONST $INT_GBL_ENABLE                 0xFFFF01;  //  RW   1 bits
   .CONST $INT_ENABLE                     0xFFFF02;  //  RW   1 bits
   .CONST $INT_CLK_SWITCH_EN              0xFFFF03;  //  RW   1 bits
   .CONST $INT_SOURCES_EN                 0xFFFF04;  //  RW  10 bits
   .CONST $INT_PRIORITIES                 0xFFFF05;  //  RW  20 bits
   .CONST $INT_LOAD_INFO                  0xFFFF06;  //  RW  15 bits
   .CONST $INT_ACK                        0xFFFF07;  //  RW   1 bits
   .CONST $INT_SOURCE                     0xFFFF08;  //  R    6 bits
   .CONST $INT_SAVE_INFO                  0xFFFF09;  //  R   14 bits

   //Interrupt Events
   .CONST $DSP2MCU_EVENT_DATA             0xFFFF0A;  //  RW  16 bits
   .CONST $MCU2DSP_EVENT_DATA             0xFFFF0C;  //  R   16 bits

   //Timer
   .CONST $TIMER1_EN                      0xFFFF0E;  //  RW   1 bits
   .CONST $TIMER2_EN                      0xFFFF0F;  //  RW   1 bits
   .CONST $TIMER1_TRIGGER                 0xFFFF10;  //  RW  24 bits
   .CONST $TIMER2_TRIGGER                 0xFFFF11;  //  RW  24 bits

   //XAP MMU
   .CONST $WRITE_PORT0_DATA               0xFFFF12;  //  W   24/16/8 bits
   .CONST $WRITE_PORT1_DATA               0xFFFF13;  //  W   24/16/8 bits
   .CONST $WRITE_PORT2_DATA               0xFFFF14;  //  W   24/16/8 bits
   .CONST $WRITE_PORT3_DATA               0xFFFF15;  //  W   24/16/8 bits
   .CONST $WRITE_PORT4_DATA               0xFFFF16;  //  W   24/16/8 bits
   .CONST $WRITE_PORT5_DATA               0xFFFF17;  //  W   24/16/8 bits
   .CONST $WRITE_PORT6_DATA               0xFFFF18;  //  W   24/16/8 bits
   .CONST $WRITE_PORT7_DATA               0xFFFF19;  //  W   24/16/8 bits
   .CONST $READ_PORT0_DATA                0xFFFF1A;  //  R   24/16/8 bits
   .CONST $READ_PORT1_DATA                0xFFFF1B;  //  R   24/16/8 bits
   .CONST $READ_PORT2_DATA                0xFFFF1C;  //  R   24/16/8 bits
   .CONST $READ_PORT3_DATA                0xFFFF1D;  //  R   24/16/8 bits
   .CONST $READ_PORT4_DATA                0xFFFF1E;  //  R   24/16/8 bits
   .CONST $READ_PORT5_DATA                0xFFFF1F;  //  R   24/16/8 bits
   .CONST $READ_PORT6_DATA                0xFFFF20;  //  R   24/16/8 bits
   .CONST $READ_PORT7_DATA                0xFFFF21;  //  R   24/16/8 bits
   .CONST $PORT_BUFFER_SET                0xFFFF22;  //  RW  0-bit


   //Mem-mapped state registers
   .CONST $MM_DOLOOP_START                0xFFFF34;  //  RW  16 bits
   .CONST $MM_DOLOOP_END                  0xFFFF35;  //  RW  16 bits
   .CONST $MM_QUOTIENT                    0xFFFF36;  //  RW  24 bits
   .CONST $MM_REM                         0xFFFF37;  //  RW  24 bits

   //Clock rate control
   .CONST $CLOCK_DIVIDE_RATE              0xFFFF40;  //  RW  4 bits
   .CONST $INT_CLOCK_DIVIDE_RATE          0xFFFF41;  //  RW  4 bits

   //PIOs
   .CONST $PIO_IN                         0xFFFF42;  //  R   24 bits
   .CONST $PIO2_IN                        0xFFFF43;  //  R   24 bits
   .CONST $PIO_OUT                        0xFFFF44;  //  RW  24 bits
   .CONST $PIO2_OUT                       0xFFFF45;  //  RW  24 bits
   .CONST $PIO_DRIVE_ENABLE               0xFFFF46;  //  RW   24 bits
   .CONST $PIO2_DRIVE_ENABLE              0xFFFF47;  //  RW   24 bits
   .CONST $PIO_EVENT_EN_MASK              0xFFFF48;  //  RW  16 bits
   .CONST $PIO2_EVENT_EN_MASK             0xFFFF49;  //  RW  16 bits

   //SW interrupt events
   .CONST $INT_SW0_EVENT                  0xFFFF4A;  //  RW  1 bits
   .CONST $INT_SW1_EVENT                  0xFFFF4B;  //  RW  1 bits
   .CONST $INT_SW2_EVENT                  0xFFFF4C;  //  RW  1 bits
   .CONST $INT_SW3_EVENT                  0xFFFF4D;  //  RW  1 bits

   //XAP/ARM/FLASH/SDRAM window control
   .CONST $DM_FLASH_WINDOW1_START_ADDR    0xFFFF4E;  //  RW  24 bits
   .CONST $DM_FLASH_WINDOW2_START_ADDR    0xFFFF4F;  //  RW  24 bits
   .CONST $DM_FLASH_WINDOW3_START_ADDR    0xFFFF50;  //  RW  24 bits
   .CONST $NOSIGNX_XAPWIN1                0xFFFF52;  //  RW  1 bits
   .CONST $NOSIGNX_XAPWIN2                0xFFFF53;  //  RW  1 bits
   .CONST $NOSIGNX_FLASHWIN1              0xFFFF54;  //  RW  1 bits
   .CONST $NOSIGNX_FLASHWIN2              0xFFFF55;  //  RW  1 bits
   .CONST $NOSIGNX_FLASHWIN3              0xFFFF56;  //  RW  1 bits
   .CONST $NOSIGNX_PMWIN                  0xFFFF57;  //  RW  1 bits
   .CONST $PM_WIN_ENABLE                  0xFFFF58;  //  RW  1 bit
   .CONST $FLASHWIN1_SDRAM_SEL            0xFFFF59;  //  RW  1  bit
   .CONST $FLASHWIN1_SDRAM_START_ADDR_LS  0xFFFF5A;  //  RW  24 bits
   .CONST $FLASHWIN1_SDRAM_START_ADDR_MS  0xFFFF5B;  //  RW  24 bits
   .CONST $FLASHWIN2_SDRAM_SEL            0xFFFF5C;  //  RW  1  bit
   .CONST $FLASHWIN2_SDRAM_START_ADDR_LS  0xFFFF5D;  //  RW  24 bits
   .CONST $FLASHWIN2_SDRAM_START_ADDR_MS  0xFFFF5E;  //  RW  24 bits
   .CONST $FLASHWIN3_SDRAM_SEL            0xFFFF5F;  //  RW  1  bit
   .CONST $FLASHWIN3_SDRAM_START_ADDR_LS  0xFFFF60;  //  RW  24 bits
   .CONST $FLASHWIN3_SDRAM_START_ADDR_MS  0xFFFF61;  //  RW  24 bits
   .CONST $MCUWIN1_ARM_SEL                0xFFFF62;  //  RW  1  bit
   .CONST $MCUWIN2_ARM_SEL                0xFFFF63;  //  RW  1  bit

   //Hardware stack setup
   .CONST $STACK_START_ADDR               0xFFFF64;  //  RW  16-bit
   .CONST $STACK_END_ADDR                 0xFFFF65;  //  RW  16-bit
   .CONST $STACK_POINTER                  0xFFFF66;  //  RW  16-bit

   //Profiling information registers
   .CONST $NUM_RUN_CLKS_MS                0xFFFF67;  //  RW  8-bit
   .CONST $NUM_RUN_CLKS_LS                0xFFFF68;  //  RW  24-bit
   .CONST $NUM_INSTRS_MS                  0xFFFF69;  //  RW  8-bit
   .CONST $NUM_INSTRS_LS                  0xFFFF6A;  //  RW  24-bit
   .CONST $NUM_STALLS_MS                  0xFFFF6B;  //  RW  8-bit
   .CONST $NUM_STALLS_LS                  0xFFFF6C;  //  RW  24-bit

   //RAW time
   .CONST $TIMER_TIME                     0xFFFF6D;  //  R   24 bits
   .CONST $TIMER_TIME_MS                  0xFFFF6E;  //  R   24 bits

   //XAP MMU Port buffer configurations
   .CONST $WRITE_PORT0_CONFIG             0xFFFF6F;  //  RW   3 bits
   .CONST $WRITE_PORT1_CONFIG             0xFFFF70;  //  RW   3 bits
   .CONST $WRITE_PORT2_CONFIG             0xFFFF71;  //  RW   3 bits
   .CONST $WRITE_PORT3_CONFIG             0xFFFF72;  //  RW   3 bits
   .CONST $WRITE_PORT4_CONFIG             0xFFFF73;  //  RW   3 bits
   .CONST $WRITE_PORT5_CONFIG             0xFFFF74;  //  RW   3 bits
   .CONST $WRITE_PORT6_CONFIG             0xFFFF75;  //  RW   3 bits
   .CONST $WRITE_PORT7_CONFIG             0xFFFF76;  //  RW   3 bits
   .CONST $READ_PORT0_CONFIG              0xFFFF77;  //  RW   4 bits
   .CONST $READ_PORT1_CONFIG              0xFFFF78;  //  RW   4 bits
   .CONST $READ_PORT2_CONFIG              0xFFFF79;  //  RW   4 bits
   .CONST $READ_PORT3_CONFIG              0xFFFF7A;  //  RW   4 bits
   .CONST $READ_PORT4_CONFIG              0xFFFF7B;  //  RW   4 bits
   .CONST $READ_PORT5_CONFIG              0xFFFF7C;  //  RW   4 bits
   .CONST $READ_PORT6_CONFIG              0xFFFF7D;  //  RW   4 bits
   .CONST $READ_PORT7_CONFIG              0xFFFF7E;  //  RW   4 bits


   //PM flash window configuration
   .CONST $PM_FLASHWIN_START_ADDR         0xFFFF8F;  //  RW   24 bits
   .CONST $PM_FLASHWIN_SIZE               0xFFFF90;  //  RW   16 bits
   .CONST $PMFLASHWIN_SDRAM_SEL           0xFFFF91;  //  RW   1  bit
   .CONST $PMFLASHWIN_SDRAM_START_LS_ADDR 0xFFFF92; //  RW   24 bits
   .CONST $PMFLASHWIN_SDRAM_START_MS_ADDR 0xFFFF93; //  RW   8  bits
   .CONST $PMFLASHWIN_SDRAM_SIZE          0xFFFF94;  //  RW   16 bits

   //Bitreverse function
   .CONST $BITREVERSE_DATA                0xFFFF99;  //  RW   24 bits

   //ALU configurations
   .CONST $ARITHMETIC_MODE                0xFFFFA0;  //  RW    5 bits

   //Fast MMU clock request
   .CONST $FORCE_FAST_MMU_CLK             0xFFFFA1;  //  RW    1 bit

#endif
