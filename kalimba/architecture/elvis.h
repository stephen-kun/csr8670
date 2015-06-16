#ifndef ELVIS_H_INCLUDED
#define ELVIS_H_INCLUDED

   #define FLASH

   // -- Memory windows and sizes --
   .CONST $FLASHWIN3_START                    0xFFD000;
   .CONST $FLASHWIN3_SIZE                     0x001000;
   .CONST $FLASHWIN2_START                    0xFFC000;
   .CONST $FLASHWIN2_SIZE                     0x001000;
   .CONST $FLASHWIN1_START                    0xFFB000;
   .CONST $FLASHWIN1_SIZE                     0x001000;
   .CONST $MCUWIN1_START                      0xFFE000;
   .CONST $MCUWIN1_SIZE                       0x001000;
   .CONST $MCUWIN2_START                      0xFFF000;
   .CONST $MCUWIN2_SIZE                       0x000F00;

   .CONST $PMWIN_HI_START                     0x004000;
   .CONST $PMWIN_LO_START                     0x006000;
   .CONST $PMWIN_SIZE                         0x001800;


   // -- Interrupt Controller constants --
   .CONST $INT_LOAD_INFO_CLR_REQ_MASK         8192;

   .CONST $INT_SOURCE_TIMER1_POSN             0;
   .CONST $INT_SOURCE_TIMER2_POSN             1;
   .CONST $INT_SOURCE_MCU_POSN                2;
   .CONST $INT_SOURCE_PIO_POSN                3;
   .CONST $INT_SOURCE_MMU_UNMAPPED_POSN       4;
   .CONST $INT_SOURCE_SW0_POSN                5;
   .CONST $INT_SOURCE_SW1_POSN                6;
   .CONST $INT_SOURCE_SW2_POSN                7;
   .CONST $INT_SOURCE_SW3_POSN                8;

   .CONST $INT_SOURCE_TIMER1_MASK             1;
   .CONST $INT_SOURCE_TIMER2_MASK             2;
   .CONST $INT_SOURCE_MCU_MASK                4;
   .CONST $INT_SOURCE_PIO_MASK                8;
   .CONST $INT_SOURCE_MMU_UNMAPPED_MASK       16;
   .CONST $INT_SOURCE_SW0_MASK                32;
   .CONST $INT_SOURCE_SW1_MASK                64;
   .CONST $INT_SOURCE_SW2_MASK                128;
   .CONST $INT_SOURCE_SW3_MASK                256;

   .CONST $INT_SOURCE_TIMER1_EVENT            0;
   .CONST $INT_SOURCE_TIMER2_EVENT            1;
   .CONST $INT_SOURCE_MCU_EVENT               2;
   .CONST $INT_SOURCE_PIO_EVENT               3;
   .CONST $INT_SOURCE_MMU_UNMAPPED_EVENT      4;
   .CONST $INT_SOURCE_SW0_EVENT               5;
   .CONST $INT_SOURCE_SW1_EVENT               6;
   .CONST $INT_SOURCE_SW2_EVENT               7;
   .CONST $INT_SOURCE_SW3_EVENT               8;


   // -- Clock rate constants --
   .CONST $CLK_DIV_1                          0;
   .CONST $CLK_DIV_2                          1;
   .CONST $CLK_DIV_4                          2;
   .CONST $CLK_DIV_8                          3;
   .CONST $CLK_DIV_16                         4;
   .CONST $CLK_DIV_32                         5;
   .CONST $CLK_DIV_64                         6;
   .CONST $CLK_DIV_128                        7;
   .CONST $CLK_DIV_256                        8;
   .CONST $CLK_DIV_512                        9;
   .CONST $CLK_DIV_1024                       10;
   .CONST $CLK_DIV_2048                       11;
   .CONST $CLK_DIV_4096                       12;
   .CONST $CLK_DIV_8192                       13;
   .CONST $CLK_DIV_16384                      14;

   // -- Maximum safe clock divide rate --
   .CONST $CLK_DIV_MAX                        $CLK_DIV_16384;


   // -- Bitserialiser definitions --
   .CONST $BITSERIALISER_RWB_MASK             0x10000;


   // -- Flag constants --
   .CONST $N_FLAG                         1;
   .CONST $Z_FLAG                         2;
   .CONST $C_FLAG                         4;
   .CONST $V_FLAG                         8;
   .CONST $UD_FLAG                        16;
   .CONST $SV_FLAG                        32;
   .CONST $BR_FLAG                        64;
   .CONST $UM_FLAG                        128;

   .CONST $NOT_N_FLAG                     (65535-$N_FLAG);
   .CONST $NOT_Z_FLAG                     (65535-$Z_FLAG);
   .CONST $NOT_C_FLAG                     (65535-$C_FLAG);
   .CONST $NOT_V_FLAG                     (65535-$V_FLAG);
   .CONST $NOT_UD_FLAG                    (65535-$UD_FLAG);
   .CONST $NOT_SV_FLAG                    (65535-$SV_FLAG);
   .CONST $NOT_BR_FLAG                    (65535-$BR_FLAG);
   .CONST $NOT_UM_FLAG                    (65535-$UM_FLAG);

#endif
