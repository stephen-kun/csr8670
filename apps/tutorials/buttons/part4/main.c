/* Copyright Cambridge Silicon Radio Limited 2008-2014 */
/* Part of BlueLab-6.5.2-Release */

/*
 * Buttons Tutorial: Part 4 - Button handlers 3 (advanced handling)
 */

#include <pio.h>
#include <stdio.h>
#include <message.h>
#include "part4_buttons.h"

typedef struct
{
    TaskData    task;   /* task is required for messages to be delivered */
    PioState    pio;    /* PIO state used by buttonparse */
} appState;

appState app;

/* Function prototypes */
static void app_handler(Task task, MessageId id, Message message);
static void handle_pio_raw(Task task, PIO_RAW_T *raw);

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

    case PIO_RAW:
        handle_pio_raw(task, (PIO_RAW_T*)message);
        break;
        
    default:
        printf("Unhandled message 0x%x\n", id);
    }
}

static const uint16 raw_pattern[] =
{
    0,                          /* no RAW_PIO_2 nor RAW_PIO_3 */
    RAW_PIO_2,                  /* only RAW_PIO_2 pressed */
    RAW_PIO_2 | RAW_PIO_3,      /* both RAW_PIO_2 and RAW_PIO_3 pressed */
    RAW_PIO_3,                  /* only RAW_PIO_3 pressed */
    RAW_PIO_2 | RAW_PIO_3,      /* both RAW_PIO_2 and RAW_PIO_3 pressed */
};

static void handle_pio_raw(Task task, PIO_RAW_T *raw)
{
    static uint16 pos = 0; /* position counter */

    printf("PIO changed, state = %x\n", raw->pio);
    
    if (raw->pio == raw_pattern[pos]) pos++;
    else pos = 0;

    if (pos == (sizeof(raw_pattern) / sizeof(uint16)))
    {
        printf("Magic button sequence pressed!\n");
        pos = 0;
    }
}

/* End-of-File */
