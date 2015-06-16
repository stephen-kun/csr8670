// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

#ifndef I2C_HEADER_INCLUDED
#define I2C_HEADER_INCLUDED

    // default PIO's to use
    .CONST $i2c.default_pio_mask.SDA                        (1<<6);
    .CONST $i2c.default_pio_mask.SCLK                       (1<<7);

    // alter (lower) to clock I2C faster than the 400KHz spec
    .CONST I2C_CLK_PERIOD_ADJUSTMENT                        1.0;


    // TODO: These speeds should be moved to architecture-specific files
    #ifdef KAL_ARCH3
        .CONST CLOCKS_PER_US                                80;
    #endif
	#ifdef KAL_ARCH5
        .CONST CLOCKS_PER_US                               120;
    #endif

    // Kalasm3: Uses casts to convert from fractional to integer type
    .CONST $i2c.CLK_LOW_PERIOD_IN_CYCLES                    round(1.3 * CLOCKS_PER_US * I2C_CLK_PERIOD_ADJUSTMENT);
    .CONST $i2c.CLK_HIGH_PERIOD_IN_CYCLES                   round(0.6 * CLOCKS_PER_US * I2C_CLK_PERIOD_ADJUSTMENT);

#endif
