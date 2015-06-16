/* Copyright Cambridge Silicon Radio Limited 2008-2014 */
/* Part of BlueLab-6.5.2-Release */

/*
 * Message Handlers and Scheduler
 */

#include <message.h>        /* Messaging API */
#include <stdio.h>          /* For 'printf' */

#define DOWN    0
#define UP      1

typedef struct _count_task_data 
{
    TaskData    count_task;
    uint8       count;
} CountTaskData;

static void count_handler(Task t, MessageId id, Message payload)
{   
    CountTaskData *ctd = (CountTaskData *) t;

    printf("Count %d\n", ctd->count);  

    if (DOWN == id)
    {
        ctd->count--;
    }
    else
    {
        ctd->count++;
    }

    if (ctd->count == 10)
    {
        id = DOWN;
    }
    else if (ctd->count == 0)
    {
        id = UP;
    }

    MessageSend(
            t,           /* Task the message is sent to */
            id,          /* Message id */
            0);          /* Message Payload */
}

static CountTaskData count_task = 
{
    { count_handler },
    0
};
   
int main(void)
{
    MessageSend(
            &count_task.count_task,     /* Task the message is sent to */ 
            UP,                         /* Message Id */
            0 );                        /* Message Payload */
    
    MessageLoop();

    return 0; 
}
