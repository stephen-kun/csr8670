/* Copyright Cambridge Silicon Radio Limited 2008-2014 */
/* Part of BlueLab-6.5.2-Release */
/* 
 * Blinking Lights - Part 3
 */
 
#include <message.h>
#include <charger.h>
#include <pio.h>                /* Peripheral Input/Output */
#include <print.h>              /* debug PRINT */

#include "led_parse_example.h"

#define DELAY 5000
#define NO_OF_PATTERNS  (5)

uint8 patterns[] = { PATTERN1, PATTERN2, PATTERN3, PATTERN4, PATTERN5 };
uint8 count;

static void led_controller1( Task t, MessageId id, Message payload )
{
    PRINT(("Pattern No. %d\n", count ));
    
    ledsPlay( patterns[count] );

    count++;
    count %= NO_OF_PATTERNS;
    
    MessageSendLater( t, 0, 0, DELAY );
}

static TaskData led_controller1_task = { led_controller1 };

int main(void)
{
#if BC5_MODULE
    /* Prevent the LED0 flashing during charging */
    ChargerConfigure(CHARGER_SUPPRESS_LED0, 1);
#endif
    
    MessageSend( &led_controller1_task, 0 , 0 );
    MessageLoop();
    
    return 0;
}
