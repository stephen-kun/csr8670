#ifndef RICK_IO_DEFS_H_INCLUDED
#define RICK_IO_DEFS_H_INCLUDED

   // Bitfield Defines
   .CONST $FLASH_CACHE_SIZE_1K_ENUM                        0x000000;
   .CONST $FLASH_CACHE_SIZE_512_ENUM                       0x000001;
   .CONST $ADDSUB_SATURATE_ON_OVERFLOW_POSN                0x000000;
   .CONST $ADDSUB_SATURATE_ON_OVERFLOW_MASK                0x000001;
   .CONST $ARITHMETIC_16BIT_MODE_POSN                      0x000001;
   .CONST $ARITHMETIC_16BIT_MODE_MASK                      0x000002;
   .CONST $DISABLE_UNBIASED_ROUNDING_POSN                  0x000002;
   .CONST $DISABLE_UNBIASED_ROUNDING_MASK                  0x000004;
   .CONST $DISABLE_FRAC_MULT_ROUNDING_POSN                 0x000003;
   .CONST $DISABLE_FRAC_MULT_ROUNDING_MASK                 0x000008;
   .CONST $DISABLE_RMAC_STORE_ROUNDING_POSN                0x000004;
   .CONST $DISABLE_RMAC_STORE_ROUNDING_MASK                0x000010;
   .CONST $FLASHWIN_CONFIG_NOSIGNX_POSN                    0x000000;
   .CONST $FLASHWIN_CONFIG_NOSIGNX_MASK                    0x000001;
   .CONST $FLASHWIN_CONFIG_24BIT_POSN                      0x000001;
   .CONST $FLASHWIN_CONFIG_24BIT_MASK                      0x000002;
   .CONST $BITMODE_POSN                                    0x000000;
   .CONST $BITMODE_MASK                                    0x000003;
   .CONST $BITMODE_8BIT_ENUM                               0x000000;
   .CONST $BITMODE_16BIT_ENUM                              0x000001;
   .CONST $BITMODE_24BIT_ENUM                              0x000002;
   .CONST $BITMODE_32BIT_ENUM                              0x000003;
   .CONST $BYTESWAP_POSN                                   0x000002;
   .CONST $BYTESWAP_MASK                                   0x000004;
   .CONST $SATURATE_POSN                                   0x000003;
   .CONST $SATURATE_MASK                                   0x000008;
   .CONST $NOSIGNEXT_POSN                                  0x000003;
   .CONST $NOSIGNEXT_MASK                                  0x000008;
   .CONST $PAD_EN_POSN                                     0x000004;
   .CONST $PAD_EN_MASK                                     0x000030;

#endif
