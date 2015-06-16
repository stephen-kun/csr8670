// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// *****************************************************************************
// NAME:
//    Basic low level I2C library
//
// DESCRIPTION:
//    TODO
//
// assume clock's default is low  - data is anything
// change SDA on or just after falling edge of SCLK
//
//
// *****************************************************************************

#include "i2c.h"
#include "stack.h"

.MODULE $i2c;
   .DATASEGMENT DM;

   .VAR $i2c.pio_sclk_mask = $i2c.default_pio_mask.SDA;
   .VAR $i2c.pio_sda_mask  = $i2c.default_pio_mask.SCLK;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $i2c.delay_high_clk
//
// DESCRIPTION:
//    Delay for 1 high period of an i2c clock this must be >0.6us to meet spec
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
//
// TRASHED REGISTERS:
//    r10, Do Loop
//
// *****************************************************************************
.MODULE $M.i2c.delay_high_clk;
   .CODESEGMENT I2C_HIGH_CLK_PM;

   $i2c.delay_high_clk:

   r10 = $i2c.CLK_HIGH_PERIOD_IN_CYCLES - 4;
   do loop;
      nop;
   loop:
   rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $i2c.delay_low_clk
//
// DESCRIPTION:
//    Delay for 1 low period of an i2c clock this must be >1.3us to meet spec
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
//
// TRASHED REGISTERS:
//    r10, Do Loop
//
// *****************************************************************************
.MODULE $M.i2c.delay_low_clk;
   .CODESEGMENT I2C_LOW_CLK_PM;

   $i2c.delay_low_clk:

   r10 = $i2c.CLK_LOW_PERIOD_IN_CYCLES - 4;
   do loop;
      nop;
   loop:
   rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $i2c.start_bit
//
// DESCRIPTION:
//    Send I2C start bit
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r10, Do Loop
//
// *****************************************************************************
.MODULE $M.i2c.start_bit;
   .CODESEGMENT I2C_START_PM;

   $i2c.start_bit:

   // push rLink onto stack
   $push_rLink_macro;

   r1 = M[$i2c.pio_sclk_mask];
   r2 = M[$i2c.pio_sda_mask];

   // if we have PIO direction control make sure SDA is set as an output
   r0 = M[$PIO_DIR];
   r0 = r0 OR r2;
   M[$PIO_DIR] = r0;

   call $i2c.delay_low_clk;

   // set SCLK high and SDA high
   r0 = M[$PIO_OUT];
   r3 = r1 + r2;
   r0 = r0 OR r3;
   M[$PIO_OUT] = r0;
   call $i2c.delay_high_clk;

   // set SCLK high and SDA low
   M[$PIO_OUT] = r0 - r2;
   call $i2c.delay_high_clk;

   // set SCLK low and SDA low
   M[$PIO_OUT] = r0 - r3;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $i2c.stop_bit
//
// DESCRIPTION:
//    Send I2C stop bit
//
// INPUTS:
//    none
//
// OUTPUTS:
//    none
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r10, Do Loop
//
// *****************************************************************************
.MODULE $M.i2c.stop_bit;
   .CODESEGMENT I2C_STOP_PM;

   $i2c.stop_bit:

   // push rLink onto stack
   $push_rLink_macro;

   r1 = M[$i2c.pio_sclk_mask];
   r2 = M[$i2c.pio_sda_mask];

   // set SCLK low and SDA low
   r0 = M[$PIO_OUT];
   r3 = r1 + r2;
   r0 = r0 OR r3;
   M[$PIO_OUT] = r0 - r3;
   call $i2c.delay_low_clk;

   // set SCLK high and SDA low
   M[$PIO_OUT] = r0 - r2;
   call $i2c.delay_high_clk;

   // set SCLK high and SDA high
   M[$PIO_OUT] = r0;
   call $i2c.delay_high_clk;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $i2c.send_byte
//
// DESCRIPTION:
//    Send a byte to the I2C bus (also read in ack bit)
//
// INPUTS:
//    - r0 = byte to send
//
// OUTPUTS:
//    - r0 = ACK bit
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r10, Do Loop
//
// NOTES:
//    We assume interrupts are blocked during this function.  This is so that
// the state of other PIOs controlled by the DSP do not change.
//
//    We assume the at entry to the routine that SCLK is low, and that we must
// delay for a half period (i.e the low period).  We leave it in this state on
// exit as well.
//
// *****************************************************************************
.MODULE $M.i2c.send_byte;
   .CODESEGMENT I2C_SEND_BYTE_PM;

   $i2c.send_byte:

   // push rLink onto stack
   $push_rLink_macro;

   // r2 = SDA mask
   r2 = M[$i2c.pio_sda_mask];

   // set r1 = default PIO state: SCLK low, SDA low
   r1 = M[$PIO_OUT];
   r4 = r2 + M[$i2c.pio_sclk_mask];
   r1 = r1 OR r4;
   r1 = r1 - r4;

   r3 = 128;
   loop:

      // set SDA accordingly (with SCLK low)
      r4 = r1;
      Null = r0 AND r3;
      if NZ r4 = r1 + r2;
      M[$PIO_OUT] = r4;
      call $i2c.delay_low_clk;

      // leave SDA and set SCLK high
      r4 = r4 + M[$i2c.pio_sclk_mask];
      M[$PIO_OUT] = r4;
      call $i2c.delay_high_clk;

      r3 = r3 LSHIFT -1;
   if NZ jump loop;

   // if we have PIO direction control set SDA to an input
   r0 = M[$PIO_DIR];
   r0 = r0 OR r2;
   r0 = r0 - r2;
   M[$PIO_DIR] = r0;

   // set SCLK low and SDA (as an output) high
   r4 = r1 + r2;
   M[$PIO_OUT] = r4;
   call $i2c.delay_low_clk;

   // read SDA bit (the ACK)
   r0 = 1;
   r1 = M[$PIO_IN];
   Null = r1 AND r2;
   if Z r0 = 0;

   // set SCLK high
   r4 = r4 + M[$i2c.pio_sclk_mask];
   M[$PIO_OUT] = r4;
   call $i2c.delay_high_clk;

   // set SCLK low
   r4 = r4 - M[$i2c.pio_sclk_mask];
   M[$PIO_OUT] = r4;

   // if we have PIO direction control set SDA back to an output
   r1 = M[$PIO_DIR];
   r1 = r1 OR r2;
   M[$PIO_DIR] = r1;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;


// *****************************************************************************
// MODULE:
//    $i2c.receive_byte
//
// DESCRIPTION:
//    Receive a byte from the I2C bus (also send ack bit)
//
// INPUTS:
//    - r0 = ACK (1 to ACK, 0 to not ACK)
//
// OUTPUTS:
//    - r0 = byte received
//
// TRASHED REGISTERS:
//    r0, r1, r2, r3, r4, r10, Do Loop
//
// NOTES:
//    We assume interrupts are blocked during this function.  This is so that
// the state of other PIOs controlled by the DSP do not change.
//
//    We assume the at entry to the routine that SCLK is low, and that we must
// delay for a half period (i.e the low period).  We leave it in this state on
// exit as well.
//
// *****************************************************************************
.MODULE $M.i2c.receive_byte;
   .CODESEGMENT I2C_RECEIVE_BYTE_PM;
   .DATASEGMENT DM;

   .VAR $i2c.send_ack;

   $i2c.receive_byte:

   // push rLink onto stack
   $push_rLink_macro;

   // store ACK state to send;
   M[$i2c.send_ack] = r0;

   // r2 = SDA mask
   r2 = M[$i2c.pio_sda_mask];

   // if we have PIO direction control set SDA to an input
   r0 = M[$PIO_DIR];
   r0 = r0 OR r2;
   M[$PIO_DIR] = r0 - r2;

   // set r1 = default PIO state: SCLK high, SDA (as an output) high
   r1 = M[$PIO_OUT];
   r0 = r2 + M[$i2c.pio_sclk_mask];
   r1 = r1 OR r0;

   r0 = 0;
   r3 = 128;
   loop:

      call $i2c.delay_low_clk;

      // read SDA bit
      r4 = M[$PIO_IN];
      Null = r4 AND r2;
      if NZ r0 = r0 + r3;

      // set SCLK high
      M[$PIO_OUT] = r1;
      call $i2c.delay_high_clk;

      // set SCLK low
      r4 = r1 - M[$i2c.pio_sclk_mask];
      M[$PIO_OUT] = r4;

      r3 = r3 LSHIFT -1;
   if NZ jump loop;

   // if we have PIO direction control set SDA back to an output
   r1 = M[$PIO_DIR];
   r1 = r1 OR r2;
   M[$PIO_DIR] = r1;

   // set SCLK low with ACK on SDA
   Null = M[$i2c.send_ack];
   if NZ r4 = r4 - r2;
   M[$PIO_OUT] = r4;
   call $i2c.delay_low_clk;

   // set SCLK high with ACK on SDA
   r4 = r4 + M[$i2c.pio_sclk_mask];
   M[$PIO_OUT] = r4;
   call $i2c.delay_high_clk;

   // set SCLK low
   r4 = r4 - M[$i2c.pio_sclk_mask];
   M[$PIO_OUT] = r4;

   // pop rLink from stack
   jump $pop_rLink_and_rts;

.ENDMODULE;
