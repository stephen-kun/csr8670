/* Copyright Cambridge Silicon Radio Limited 2008-2014 */
/* Part of BlueLab-6.5.2-Release */

/*
 * Buttons Tutorial: Part 3 - Button handlers 2 (held, held+release and repeat)
 */

#include <pio.h>
#include <stdio.h>
#include <message.h>
#include "part3_buttons.h"

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
    case AB_HELD:
        printf("Buttons A and B held 1s\n");
        break;

    case A_HELD_RELEASE:
        printf("Button A released after held over 3s\n");
        break;

    case B_HELD:
        printf("Button B held 1s\n");
        break;

    default:
        printf("Unhandled message 0x%x\n", id);
    }
}

/* End-of-File */
