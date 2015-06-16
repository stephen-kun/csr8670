// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio plc 2004-2014        http://www.csr.com
// Part of ADK 3.5
//
// Amber Kalimba DSP Assembler Default File
//
// This file contains things which do not normally alter
// (e.g. segment defines and hardware register values)
// This file is only used by the assembler, and therefore
// contains anything that the assembler understands.
//
// *****************************************************************************

#ifndef AMBER_H_INCLUDED
#define AMBER_H_INCLUDED

// -- Memory windows and sizes --
.CONST $NVMEM_DM_WIN0_START                0xC00000;
.CONST $NVMEM_DM_WIN0_SIZE                 0x200000;
.CONST $NVMEM_DM_WIN1_START                0xA00000;
.CONST $NVMEM_DM_WIN1_SIZE                 0x200000;
.CONST $NVMEM_DM_WIN2_START                0x800000;
.CONST $NVMEM_DM_WIN2_SIZE                 0x200000;

.CONST $NVMEM_PM_WIN0_START                0x00400000;
.CONST $NVMEM_PM_WIN0_SIZE                 0x00400000;
.CONST $NVMEM_PM_WIN1_START                0x00800000;
.CONST $NVMEM_PM_WIN1_SIZE                 0x00400000;
.CONST $NVMEM_PM_WIN2_START                0x00C00000;
.CONST $NVMEM_PM_WIN2_SIZE                 0x00400000;

// -- Clock rate constants --
.CONST $CLK_DIV_STOPPED                    0;
.CONST $CLK_DIV_1                          1;
.CONST $CLK_DIV_2                          2;
.CONST $CLK_DIV_4                          4;
.CONST $CLK_DIV_8                          8;
.CONST $CLK_DIV_16                         16;
.CONST $CLK_DIV_32                         32;
.CONST $CLK_DIV_64                         64;
.CONST $CLK_DIV_128                        128;
.CONST $CLK_DIV_256                        256;
.CONST $CLK_DIV_512                        512;
.CONST $CLK_DIV_1024                       1024;
.CONST $CLK_DIV_2048                       2048;
.CONST $CLK_DIV_4096                       4096;
.CONST $CLK_DIV_8192                       8192;
.CONST $CLK_DIV_16384                      16384;

// -- Flag constants --
.CONST $N_FLAG                         1;
.CONST $Z_FLAG                         2;
.CONST $C_FLAG                         4;
.CONST $V_FLAG                         8;
.CONST $UD_FLAG                        16;
.CONST $SV_FLAG                        32;
.CONST $BR_FLAG                        64;
.CONST $UM_FLAG                        128;

.CONST $NOT_N_FLAG                     ~$N_FLAG;
.CONST $NOT_Z_FLAG                     ~$Z_FLAG;
.CONST $NOT_C_FLAG                     ~$C_FLAG;
.CONST $NOT_V_FLAG                     ~$V_FLAG;
.CONST $NOT_UD_FLAG                    ~$UD_FLAG;
.CONST $NOT_SV_FLAG                    ~$SV_FLAG;
.CONST $NOT_BR_FLAG                    ~$BR_FLAG;
.CONST $NOT_UM_FLAG                    ~$UM_FLAG;


// Architecture and bitwidth defines
.CONST $DAWTH                   32;
.CONST $ADDR_PER_WORD           4;
.CONST $LOG2_ADDR_PER_WORD      2;
.CONST $PC_PER_INSTRUCTION      4;
.CONST $LOG2_PC_PER_INSTRUCTION 2;
.CONST $DAWTH_MASK              0xFFFFFFFF;
.CONST $WORD_ADDRESS_MASK       0xFFFFFFFC;
.CONST $MAXINT                  0x7FFFFFFF;
.CONST $MININT                  0x80000000;


// Define RAM sizes:
.CONST $PM_SIZE             0x9000;
.CONST $DM_RAM_SIZE         0x40000;

.CONST $PM_2WAYSA_CACHE_TAGS_START_ADDR   0x8000;
.CONST $PM_2WAYSA_CACHE_TAGS_SIZE         0x800;


// Defines for RAM start addresses and sizes
.CONST $DM1_RAM_START_ADDR  0x00000000;
.CONST $DM2_RAM_START_ADDR  0xFFF80000;
.CONST $DM1_RAM_END_ADDR    $DM1_RAM_START_ADDR + $DM_RAM_SIZE - $ADDR_PER_WORD;
.CONST $DM2_RAM_END_ADDR    $DM2_RAM_START_ADDR + $DM_RAM_SIZE - $ADDR_PER_WORD;

// Clock speed (MHz)
.CONST $CLOCK_SPEED_MHZ     120;


#endif
