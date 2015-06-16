/* Copyright Cambridge Silicon Radio Limited 2008-2014 */
/* Part of BlueLab-6.5.2-Release */

/*
 * Buttons Tutorial: Part 1 - PIO messages
 */

#include <pio.h>
#include <stdio.h>
#include <message.h>

#define BUTTON_A        (1 << 0)        /* PIO0 is BUTTON_A */
#define BUTTON_B        (1 << 1)        /* PIO1 is BUTTON_B */
#define BUTTON_C        (1 << 2)        /* PIO2 is BUTTON_C */
#define BUTTON_D        (1 << 3)        /* PIO3 is BUTTON_D */

typedef struct
{
    TaskData    task;   /* task is required for messages to be delivered */
} appState;

appState app;

/* Function prototypes */
static void app_handler(Task task, MessageId id, Message message);
static void handle_pio(Task task, MessagePioChanged *pio);

int main(void)
{
    /* Set app_handler() function to handle app's messages */
    app.task.handler = app_handler;

    /* Set app task to receive PIO messages */
    MessagePioTask(&app.task);

    /* Setup PIO interrupt messages */
    PioDebounce32(BUTTON_A | BUTTON_B,  /* PIO pins we are interested in */
                2, 20);                 /* 2 reads and 20ms between them */

    MessageLoop();
    
    return 0;
}

static void app_handler(Task task, MessageId id, Message message) 
{
    switch (id)
    {
    case MESSAGE_PIO_CHANGED:
        handle_pio(task, (MessagePioChanged*)message);
        break;

    default:
        printf("Unhandled message 0x%x\n", id);
    }
}

static void handle_pio(Task task, MessagePioChanged *pio)
{
    if (pio->state & BUTTON_A) printf("Button A pressed\n");
    if (pio->state & BUTTON_B) printf("Button B pressed\n");    
}

/* End-of-File */
