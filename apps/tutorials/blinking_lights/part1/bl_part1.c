/* Copyright Cambridge Silicon Radio Limited 2008-2014 */
/* Part of BlueLab-6.5.2-Release */
/*
 * Blinking Lights - Part 1
 */

#include <message.h>
#include <pio.h>		/* Peripheral Input/Output */

#define LED1 	 0x01    	/* bit 1 */
#define DELAY1   200 		/* ms */

#define LED2     0x02 		/* bit 2 */
#define DELAY2   400 		/* ms */

static void led_controller1( Task t, MessageId id, Message payload )
{
	PioSet32( LED1, (PioGet32() ^ LED1) );
	MessageSendLater( t, 0, 0, DELAY1 );
}

static void led_controller2( Task t, MessageId id, Message payload )
{
	PioSet32( LED2, (PioGet32() ^ LED2) );
	MessageSendLater( t, 0, 0, DELAY2 );
}

static TaskData led_controller1_task = { led_controller1 };
static TaskData led_controller2_task = { led_controller2 };


int main(void)
{
	PioSetDir32(0xFF, 0xFF);         /* Set all PIO to be output */
	PioSet32(0xFF, 0);               /* Set all PIO off (0) */
	
	MessageSend( &led_controller1_task, 0 , 0 );
	MessageSend( &led_controller2_task, 0 , 0 );
	MessageLoop();
	
	return 0;
}
