/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2014

PROJECT
    source

FILE NAME
    source_led_error.c

DESCRIPTION
    Indicates Configuration Set and PS store Errors using the system LEDs

*/


/* header for this file */
#include "source_led_error.h"

#include <led.h>
#include <pio.h>
#include <message.h>
#include <panic.h>

/****************************************************************************
NAME
    LedsIndicateError

DESCRIPTION
    Indicates a fatal application error by flashing each LED in turn the
    number of times of the specified error id.
    This function never returns.
RETURNS
    void
*/
void LedsIndicateError ( const uint16 errId )
{
    uint8 ledId = LED_0;

    /* init leds */
    for (ledId = LED_0; ledId <= LED_2; ledId++)
    {
        LedConfigure(ledId, LED_DUTY_CYCLE, 0x0);
        LedConfigure(ledId, LED_FLASH_ENABLE, 0);
        LedConfigure(ledId, LED_ENABLE, 1);
    }

    /* Never leave this function */
    while (TRUE)
    {
        /* flash each led in turn */
        for (ledId = LED_0; ledId <= LED_2; ledId++)
        {
            uint16 flashCount = 0;
            uint16 waitCounter = 0;
            /* Flash the number of times corresponding to the config id error */
            for(flashCount = 0; flashCount < errId; flashCount++)
            {
                uint16 intensity = 0x0;

                /* Fade in */
                for (intensity=0x0; intensity <= 0x0FFF; intensity++)
                {

                    LedConfigure(ledId, LED_DUTY_CYCLE, intensity);

                    /* wait */
                    waitCounter = 0;
                    while (waitCounter < 0x09FF)
                    {
                        waitCounter++;
                    }
                }

                LedConfigure(ledId, LED_DUTY_CYCLE, 0);
            }

            waitCounter = 0;
            while (waitCounter < 0x0FFF)
            {
                waitCounter++;
            }
        }
    }
}
