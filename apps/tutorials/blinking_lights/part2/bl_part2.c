/* Copyright Cambridge Silicon Radio Limited 2008-2014 */
/* Part of BlueLab-6.5.2-Release */
/* 
 * Blinking Lights - Part 2
 */

#include <charger.h>
#include <pio.h>

/* 
 * NOTE: This tutorial will only work for certain BlueCore variants that support
 * the dedicated LED output, such as BC5MM.
 */

int main(void)
{
    /* Prevent the LED0 flashing during charging */
    ChargerConfigure(CHARGER_SUPPRESS_LED0, 1);
   
    /* Enable LEDs */
    LedConfigure(LED_0, LED_ENABLE, 1);
    LedConfigure(LED_1, LED_ENABLE, 1);
    
    /* Set the intensity */
    LedConfigure(LED_0, LED_DUTY_CYCLE, 0x7FF);
    LedConfigure(LED_1, LED_DUTY_CYCLE, 0x7FF);

    /* Set the PWM period */
    LedConfigure(LED_0, LED_PERIOD, 0x1);
    LedConfigure(LED_1, LED_PERIOD, 0x1);

    /* Pulse the LEDs */
    LedConfigure(LED_0, LED_FLASH_ENABLE, 1);
    LedConfigure(LED_0, LED_FLASH_RATE, 0x7);   /* Pulse the LED_0 slowly */
   
    LedConfigure(LED_1, LED_FLASH_ENABLE, 1);
    LedConfigure(LED_1, LED_FLASH_RATE, 0x4);   /* Pulse the LED_1 quickly */
    
    return 0;
}
