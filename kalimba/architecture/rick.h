#ifndef RICK_H_INCLUDED
#define RICK_H_INCLUDED

   #define FLASH


    // -- Memory windows and sizes --
   .CONST $FLASHWIN1_START                       0xFFB000;
   .CONST $FLASHWIN1_SIZE                        0x001000;
   .CONST $FLASHWIN2_START                       0xFFC000;
   .CONST $FLASHWIN2_SIZE                        0x001000;
   .CONST $FLASHWIN3_START                       0xFFD000;
   .CONST $FLASHWIN3_SIZE                        0x001000;
   .CONST $MCUWIN1_START                         0xFFE000;
   .CONST $MCUWIN1_SIZE                          0x001000;
   .CONST $MCUWIN2_START                         0xFFF000;
   .CONST $MCUWIN2_SIZE                          0x000E00;

   .CONST $PMWIN_HI_START                        0x020000;
   .CONST $PMWIN_LO_START                        0x030000;
   .CONST $PMWIN_24_START                        0x040000;
   .CONST $PMWIN_SIZE                            0x003000;

   .CONST $FLASHWIN1_LARGE_START                 0xD00000;
   .CONST $FLASHWIN1_LARGE_SIZE                  0x100000;
   .CONST $FLASHWIN2_LARGE_START                 0xE00000;
   .CONST $FLASHWIN2_LARGE_SIZE                  0x100000;
   .CONST $FLASHWIN3_LARGE_START                 0xF00000;
   .CONST $FLASHWIN3_LARGE_SIZE                  0x0D0000;




    // -- Interrupt Controller constants --
   .CONST $INT_LOAD_INFO_CLR_REQ_MASK         16384;

   .CONST $INT_LOW_PRI_SOURCES_EN_TIMER1_POSN              0x000000;
   .CONST $INT_LOW_PRI_SOURCES_EN_TIMER2_POSN              0x000001;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW_ERROR_POSN            0x000002;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW0_POSN                 0x000003;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW1_POSN                 0x000004;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW2_POSN                 0x000005;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW3_POSN                 0x000006;
   .CONST $INT_LOW_PRI_SOURCES_EN_MCU_TO_DSP_EVENT_POSN    0x000007;
   .CONST $INT_LOW_PRI_SOURCES_EN_PIO_EVENT_POSN           0x000008;
   .CONST $INT_LOW_PRI_SOURCES_EN_UNUSED_EVENT_POSN        0x000009;
   .CONST $INT_LOW_PRI_SOURCES_EN_MMU_UNMAPPED_EVENT_POSN  0x00000a;

   .CONST $INT_LOW_PRI_SOURCES_EN_TIMER1_MASK              0x000001;
   .CONST $INT_LOW_PRI_SOURCES_EN_TIMER2_MASK              0x000002;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW_ERROR_MASK            0x000004;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW0_MASK                 0x000008;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW1_MASK                 0x000010;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW2_MASK                 0x000020;
   .CONST $INT_LOW_PRI_SOURCES_EN_SW3_MASK                 0x000040;
   .CONST $INT_LOW_PRI_SOURCES_EN_MCU_TO_DSP_EVENT_MASK    0x000080;
   .CONST $INT_LOW_PRI_SOURCES_EN_PIO_EVENT_MASK           0x000100;
   .CONST $INT_LOW_PRI_SOURCES_EN_UNUSED_EVENT_MASK        0x000200;
   .CONST $INT_LOW_PRI_SOURCES_EN_MMU_UNMAPPED_EVENT_MASK  0x000400;

   .CONST $INT_MED_PRI_SOURCES_EN_TIMER1_POSN              0x000000;
   .CONST $INT_MED_PRI_SOURCES_EN_TIMER2_POSN              0x000001;
   .CONST $INT_MED_PRI_SOURCES_EN_SW_ERROR_POSN            0x000002;
   .CONST $INT_MED_PRI_SOURCES_EN_SW0_POSN                 0x000003;
   .CONST $INT_MED_PRI_SOURCES_EN_SW1_POSN                 0x000004;
   .CONST $INT_MED_PRI_SOURCES_EN_SW2_POSN                 0x000005;
   .CONST $INT_MED_PRI_SOURCES_EN_SW3_POSN                 0x000006;
   .CONST $INT_MED_PRI_SOURCES_EN_MCU_TO_DSP_EVENT_POSN    0x000007;
   .CONST $INT_MED_PRI_SOURCES_EN_PIO_EVENT_POSN           0x000008;
   .CONST $INT_MED_PRI_SOURCES_EN_UNUSED_EVENT_POSN        0x000009;
   .CONST $INT_MED_PRI_SOURCES_EN_MMU_UNMAPPED_EVENT_POSN  0x00000a;

   .CONST $INT_MED_PRI_SOURCES_EN_TIMER1_MASK              0x000001;
   .CONST $INT_MED_PRI_SOURCES_EN_TIMER2_MASK              0x000002;
   .CONST $INT_MED_PRI_SOURCES_EN_SW_ERROR_MASK            0x000004;
   .CONST $INT_MED_PRI_SOURCES_EN_SW0_MASK                 0x000008;
   .CONST $INT_MED_PRI_SOURCES_EN_SW1_MASK                 0x000010;
   .CONST $INT_MED_PRI_SOURCES_EN_SW2_MASK                 0x000020;
   .CONST $INT_MED_PRI_SOURCES_EN_SW3_MASK                 0x000040;
   .CONST $INT_MED_PRI_SOURCES_EN_MCU_TO_DSP_EVENT_MASK    0x000080;
   .CONST $INT_MED_PRI_SOURCES_EN_PIO_EVENT_MASK           0x000100;
   .CONST $INT_MED_PRI_SOURCES_EN_UNUSED_EVENT_MASK        0x000200;
   .CONST $INT_MED_PRI_SOURCES_EN_MMU_UNMAPPED_EVENT_MASK  0x000400;

   .CONST $INT_HIGH_PRI_SOURCES_EN_TIMER1_POSN             0x000000;
   .CONST $INT_HIGH_PRI_SOURCES_EN_TIMER2_POSN             0x000001;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW_ERROR_POSN           0x000002;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW0_POSN                0x000003;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW1_POSN                0x000004;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW2_POSN                0x000005;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW3_POSN                0x000006;
   .CONST $INT_HIGH_PRI_SOURCES_EN_MCU_TO_DSP_EVENT_POSN   0x000007;
   .CONST $INT_HIGH_PRI_SOURCES_EN_PIO_EVENT_POSN          0x000008;
   .CONST $INT_HIGH_PRI_SOURCES_EN_UNUSED_EVENT_POSN       0x000009;
   .CONST $INT_HIGH_PRI_SOURCES_EN_MMU_UNMAPPED_EVENT_POSN 0x00000a;

   .CONST $INT_HIGH_PRI_SOURCES_EN_TIMER1_MASK             0x000001;
   .CONST $INT_HIGH_PRI_SOURCES_EN_TIMER2_MASK             0x000002;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW_ERROR_MASK           0x000004;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW0_MASK                0x000008;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW1_MASK                0x000010;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW2_MASK                0x000020;
   .CONST $INT_HIGH_PRI_SOURCES_EN_SW3_MASK                0x000040;
   .CONST $INT_HIGH_PRI_SOURCES_EN_MCU_TO_DSP_EVENT_MASK   0x000080;
   .CONST $INT_HIGH_PRI_SOURCES_EN_PIO_EVENT_MASK          0x000100;
   .CONST $INT_HIGH_PRI_SOURCES_EN_UNUSED_EVENT_MASK       0x000200;
   .CONST $INT_HIGH_PRI_SOURCES_EN_MMU_UNMAPPED_EVENT_MASK 0x000400;


   .CONST $INT_SOURCE_LOW_TO_MED_PRI_ENUM_GAP              0x000030;
   .CONST $INT_SOURCE_MED_TO_HIGH_PRI_ENUM_GAP             0x000030;


   .CONST $INT_SOURCE_LOW_PRI_TIMER1_EVENT_ENUM            0x000000;
   .CONST $INT_SOURCE_LOW_PRI_TIMER2_EVENT_ENUM            0x000001;
   .CONST $INT_SOURCE_LOW_PRI_SW_ERROR_EVENT_ENUM          0x000002;
   .CONST $INT_SOURCE_LOW_PRI_SW0_EVENT_ENUM               0x000003;
   .CONST $INT_SOURCE_LOW_PRI_SW1_EVENT_ENUM               0x000004;
   .CONST $INT_SOURCE_LOW_PRI_SW2_EVENT_ENUM               0x000005;
   .CONST $INT_SOURCE_LOW_PRI_SW3_EVENT_ENUM               0x000006;
   .CONST $INT_SOURCE_LOW_PRI_MCU_TO_DSP_EVENT_ENUM        0x000007;
   .CONST $INT_SOURCE_LOW_PRI_PIO_EVENT_ENUM               0x000008;
   .CONST $INT_SOURCE_LOW_PRI_UNUSED_EVENT_ENUM            0x000009;
   .CONST $INT_SOURCE_LOW_PRI_MMU_UNMAPPED_EVENT_ENUM      0x00000a;

   .CONST $INT_SOURCE_MED_PRI_TIMER1_EVENT_ENUM            0x000030;
   .CONST $INT_SOURCE_MED_PRI_TIMER2_EVENT_ENUM            0x000031;
   .CONST $INT_SOURCE_MED_PRI_SW_ERROR_EVENT_ENUM          0x000032;
   .CONST $INT_SOURCE_MED_PRI_SW0_EVENT_ENUM               0x000033;
   .CONST $INT_SOURCE_MED_PRI_SW1_EVENT_ENUM               0x000034;
   .CONST $INT_SOURCE_MED_PRI_SW2_EVENT_ENUM               0x000035;
   .CONST $INT_SOURCE_MED_PRI_SW3_EVENT_ENUM               0x000036;
   .CONST $INT_SOURCE_MED_PRI_MCU_TO_DSP_EVENT_ENUM        0x000037;
   .CONST $INT_SOURCE_MED_PRI_PIO_EVENT_ENUM               0x000038;
   .CONST $INT_SOURCE_MED_PRI_UNUSED_EVENT_ENUM            0x000039;
   .CONST $INT_SOURCE_MED_PRI_MMU_UNMAPPED_EVENT_ENUM      0x00003a;

   .CONST $INT_SOURCE_HIGH_PRI_TIMER1_EVENT_ENUM           0x000060;
   .CONST $INT_SOURCE_HIGH_PRI_TIMER2_EVENT_ENUM           0x000061;
   .CONST $INT_SOURCE_HIGH_PRI_SW_ERROR_EVENT_ENUM         0x000062;
   .CONST $INT_SOURCE_HIGH_PRI_SW0_EVENT_ENUM              0x000063;
   .CONST $INT_SOURCE_HIGH_PRI_SW1_EVENT_ENUM              0x000064;
   .CONST $INT_SOURCE_HIGH_PRI_SW2_EVENT_ENUM              0x000065;
   .CONST $INT_SOURCE_HIGH_PRI_SW3_EVENT_ENUM              0x000066;
   .CONST $INT_SOURCE_HIGH_PRI_MCU_TO_DSP_EVENT_ENUM       0x000067;
   .CONST $INT_SOURCE_HIGH_PRI_PIO_EVENT_ENUM              0x000068;
   .CONST $INT_SOURCE_HIGH_PRI_UNUSED_EVENT_ENUM           0x000069;
   .CONST $INT_SOURCE_HIGH_PRI_MMU_UNMAPPED_EVENT_ENUM     0x00006a;

   .CONST $INT_LOAD_INFO_PRIORITY_POSN                     0x000000;
   .CONST $INT_LOAD_INFO_SOURCE_POSN                       0x000002;
   .CONST $INT_LOAD_INFO_INT_ACTIVE_POSN                   0x00000a;
   .CONST $INT_LOAD_INFO_REQUEST_POSN                      0x00000b;
   .CONST $INT_LOAD_INFO_DONT_CLEAR_POSN                   0x000013;

   .CONST $INT_LOAD_INFO_PRIORITY_MASK                     0x000003;
   .CONST $INT_LOAD_INFO_SOURCE_MASK                       0x0003fc;
   .CONST $INT_LOAD_INFO_INT_ACTIVE_MASK                   0x000400;
   .CONST $INT_LOAD_INFO_REQUEST_MASK                      0x07f800;
   .CONST $INT_LOAD_INFO_DONT_CLEAR_MASK                   0x080000;

   .CONST $INT_SAVE_INFO_PRIORITY_POSN                     0x000000;
   .CONST $INT_SAVE_INFO_SOURCE_POSN                       0x000002;
   .CONST $INT_SAVE_INFO_ACTIVE_POSN                       0x00000a;
   .CONST $INT_SAVE_INFO_SOURCE_NEW_POSN                   0x00000b;

   .CONST $INT_SAVE_INFO_PRIORITY_MASK                     0x000003;
   .CONST $INT_SAVE_INFO_SOURCE_MASK                       0x0003fc;
   .CONST $INT_SAVE_INFO_ACTIVE_MASK                       0x000400;
   .CONST $INT_SAVE_INFO_SOURCE_NEW_MASK                   0x07f800;




   // -- Clock rate constants --
   .CONST $CLK_DIV_1                          0;
   .CONST $CLK_DIV_2                          1;
   .CONST $CLK_DIV_4                          3;
   .CONST $CLK_DIV_8                          7;
   .CONST $CLK_DIV_16                         15;
   .CONST $CLK_DIV_32                         31;
   .CONST $CLK_DIV_64                         63;
   .CONST $CLK_DIV_128                        127;
   .CONST $CLK_DIV_256                        255;
   .CONST $CLK_DIV_512                        511;
   .CONST $CLK_DIV_1024                       1023;
   .CONST $CLK_DIV_2048                       2047;
   .CONST $CLK_DIV_4096                       4095;
   .CONST $CLK_DIV_8192                       8191;
   .CONST $CLK_DIV_16384                      16383;

   // -- Maximum safe clock divide rate --
   .CONST $CLK_DIV_MAX                        $CLK_DIV_64;


   // -- Flag constants --
   .CONST $N_FLAG_POSN                                     0x000000;
   .CONST $N_FLAG_MASK                                     0x000001;
   .CONST $Z_FLAG_POSN                                     0x000001;
   .CONST $Z_FLAG_MASK                                     0x000002;
   .CONST $C_FLAG_POSN                                     0x000002;
   .CONST $C_FLAG_MASK                                     0x000004;
   .CONST $V_FLAG_POSN                                     0x000003;
   .CONST $V_FLAG_MASK                                     0x000008;
   .CONST $UD_FLAG_POSN                                    0x000004;
   .CONST $UD_FLAG_MASK                                    0x000010;
   .CONST $SV_FLAG_POSN                                    0x000005;
   .CONST $SV_FLAG_MASK                                    0x000020;
   .CONST $BR_FLAG_POSN                                    0x000006;
   .CONST $BR_FLAG_MASK                                    0x000040;
   .CONST $UM_FLAG_POSN                                    0x000007;
   .CONST $UM_FLAG_MASK                                    0x000080;

   .CONST $INT_N_FLAG_POSN                                 0x000008;
   .CONST $INT_N_FLAG_MASK                                 0x000100;
   .CONST $INT_Z_FLAG_POSN                                 0x000009;
   .CONST $INT_Z_FLAG_MASK                                 0x000200;
   .CONST $INT_C_FLAG_POSN                                 0x00000a;
   .CONST $INT_C_FLAG_MASK                                 0x000400;
   .CONST $INT_V_FLAG_POSN                                 0x00000b;
   .CONST $INT_V_FLAG_MASK                                 0x000800;
   .CONST $INT_UD_FLAG_POSN                                0x00000c;
   .CONST $INT_UD_FLAG_MASK                                0x001000;
   .CONST $INT_SV_FLAG_POSN                                0x00000d;
   .CONST $INT_SV_FLAG_MASK                                0x002000;
   .CONST $INT_BR_FLAG_POSN                                0x00000e;
   .CONST $INT_BR_FLAG_MASK                                0x004000;
   .CONST $INT_UM_FLAG_POSN                                0x00000f;
   .CONST $INT_UM_FLAG_MASK                                0x008000;

   // -- Legacy names for flag constants --
   .CONST $N_FLAG                         $N_FLAG_MASK;
   .CONST $Z_FLAG                         $Z_FLAG_MASK;
   .CONST $C_FLAG                         $C_FLAG_MASK;
   .CONST $V_FLAG                         $V_FLAG_MASK;
   .CONST $UD_FLAG                        $UD_FLAG_MASK;
   .CONST $SV_FLAG                        $SV_FLAG_MASK;
   .CONST $BR_FLAG                        $BR_FLAG_MASK;
   .CONST $UM_FLAG                        $UM_FLAG_MASK;

   .CONST $NOT_N_FLAG                     (65535-$N_FLAG);
   .CONST $NOT_Z_FLAG                     (65535-$Z_FLAG);
   .CONST $NOT_C_FLAG                     (65535-$C_FLAG);
   .CONST $NOT_V_FLAG                     (65535-$V_FLAG);
   .CONST $NOT_UD_FLAG                    (65535-$UD_FLAG);
   .CONST $NOT_SV_FLAG                    (65535-$SV_FLAG);
   .CONST $NOT_BR_FLAG                    (65535-$BR_FLAG);
   .CONST $NOT_UM_FLAG                    (65535-$UM_FLAG);

   // symbols for backwards compatibility
   .CONST $INT_SOURCE_TIMER1_EVENT                         $INT_SOURCE_LOW_PRI_TIMER1_EVENT_ENUM;
   .CONST $INT_SOURCE_TIMER2_EVENT                         $INT_SOURCE_LOW_PRI_TIMER2_EVENT_ENUM;
   .CONST $INT_SOURCE_SW_ERROR_EVENT                       $INT_SOURCE_LOW_PRI_SW_ERROR_EVENT_ENUM;
   .CONST $INT_SOURCE_SW0_EVENT                            $INT_SOURCE_LOW_PRI_SW0_EVENT_ENUM;
   .CONST $INT_SOURCE_SW1_EVENT                            $INT_SOURCE_LOW_PRI_SW1_EVENT_ENUM;
   .CONST $INT_SOURCE_SW2_EVENT                            $INT_SOURCE_LOW_PRI_SW2_EVENT_ENUM;
   .CONST $INT_SOURCE_SW3_EVENT                            $INT_SOURCE_LOW_PRI_SW3_EVENT_ENUM;
   .CONST $INT_SOURCE_MCU_TO_DSP_EVENT                     $INT_SOURCE_LOW_PRI_MCU_TO_DSP_EVENT_ENUM;
   .CONST $INT_SOURCE_PIO_EVENT                            $INT_SOURCE_LOW_PRI_PIO_EVENT_ENUM;
   .CONST $INT_SOURCE_UNUSED_EVENT                         $INT_SOURCE_LOW_PRI_UNUSED_EVENT_ENUM;
   .CONST $INT_SOURCE_MMU_UNMAPPED_EVENT                   $INT_SOURCE_LOW_PRI_MMU_UNMAPPED_EVENT_ENUM;

#endif
