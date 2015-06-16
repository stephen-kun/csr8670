/* Copyright Cambridge Silicon Radio Limited 2008-2014 */
/* Part of BlueLab-6.5.2-Release */

/*
 * Buttons Tutorial: Part 2 - Button handlers 1 (enter, release and double)
 */

#include <pio.h>
#include <stdio.h>
#include <message.h>
#include "part2_buttons.h"

typedef struct
{
    TaskData    task;   /* task is required for messages to be delivered */
    PioState    pio;    /* PIO state used by buttonparse */
} appState;

appState app;

/* Function prototypes */
static void app_handler(Task task, MessageId id, Message message);

int main(void)
{
    /* Set app_handler() function to handle app's messages */
    app.task.handler = app_handler;

    /* Set app task to receive button messages */
    pioInit(&app.pio, &app.task);

    MessageLoop();
    
    return 0;
}

static void app_handler(Task task, MessageId id, Message message) 
{
    switch (id)
    {
    case A_PRESS:
        printf("Button A pressed\n");
        break;

    case B_RELEASE:
        printf("Button B released\n");
        break;

    case A_DOUBLE:
        printf("Button A double-pressed\n");
        break;

    default:
        printf("Unhandled message 0x%x\n", id);
    }
}

/* End-of-File */
