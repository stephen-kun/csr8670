// *****************************************************************************
// Copyright (C) Cambridge Silicon Radio Limited 2005-2014        http://www.csr.com
// Part of ADK 3.5
//
// $Change: 1882869 $  $DateTime: 2014/04/23 13:37:24 $
// *****************************************************************************

// Header file for C stubs of "core" library
// Comments show the syntax to call the routine

#if !defined(CORE_LIBRARY_C_STUBS_H)
#define CORE_LIBRARY_C_STUBS_H



/* **************************************************************************
                              -- interrupt --
   **************************************************************************/


/* PUBLIC TYPES DEFINITIONS *************************************************/


/* PUBLIC FUNCTION PROTOTYPES ***********************************************/
void interrupt_initialise( void );

void interrupt_block( void );

void interrupt_unblock( void );

void interrupt_register(int int_source, int int_priority, void (*IntFunction) (void));






/* **************************************************************************
                                -- timer --
   **************************************************************************/

/* PUBLIC TYPES DEFINITIONS *************************************************/
typedef struct tTimerStuctTag
{
    struct tTimerStuctTag *next;
    unsigned int time;
    void (*TimerEventFunction) (void);
    int id;
} tTimerStruct;



/* PUBLIC FUNCTION PROTOTYPES ***********************************************/
int timer_schedule_event_at(tTimerStruct *pTimerStruc, unsigned int time_absolute, void (*TimerEventFunction) (void));

int timer_schedule_event_in(tTimerStruct *pTimerStruc, int time_in, void (*TimerEventFunction) (void));

int timer_schedule_event_in_period(tTimerStruct *pTimerStruc, int time_period, void (*TimerEventFunction) (void));

void timer_cancel_event(int timer_id);

void timer_1ms_delay( void );

void timer_n_ms_delay( int delay_duration_ms );

void timer_n_us_delay( int delay_duration_us );






/* **************************************************************************
                                -- cbuffer --
   **************************************************************************/

/* PUBLIC TYPES DEFINITIONS *************************************************/
typedef struct
{
    int size;
    int *read_ptr;
    int *write_ptr;
} tCbuffer;



/* PUBLIC FUNCTION PROTOTYPES ***********************************************/
void cbuffer_initialise( void );

int cbuffer_is_it_enabled (tCbuffer *cbuffer);

void cbuffer_get_read_address_and_size (tCbuffer *cbuffer, int * read_ptr, int * buffer_size);

void cbuffer_get_write_address_and_size (tCbuffer *cbuffer, int * write_ptr, int * buffer_size);

void cbuffer_set_read_address (tCbuffer *cbuffer, int read_ptr);

void cbuffer_set_write_address (tCbuffer *cbuffer, int write_ptr);

int cbuffer_calc_amount_space (tCbuffer *cbuffer);

int cbuffer_calc_amount_data (tCbuffer *cbuffer);

int cbuffer_read (tCbuffer *cbuffer, int * buffer, int buffer_size);

int cbuffer_write (tCbuffer *cbuffer, int * buffer, int buffer_size);






/* **************************************************************************
                                -- message --
   **************************************************************************/

/* PUBLIC TYPES DEFINITIONS *************************************************/
typedef struct
{
    struct tMessageStruct *next;
    int id;
    void (*MessageEventFunction) (void);
    int mask;
} tMessageStruct;



/* PUBLIC FUNCTION PROTOTYPES ***********************************************/
void message_initialise( void );

void message_register_handler (void (*MessageEventFunction) (void), tMessageStruct message_struc, int message_id);

void message_send_ready_wait_for_go( void );

void message_send_short(int message_id, int p0, int p1, int p2, int p3);

void message_send_long(int message_id, int msg_size, int * msg_payload);





/* **************************************************************************
                                -- exit and debug --
   **************************************************************************/

/* PUBLIC FUNCTION PROTOTYPES ***********************************************/

void exit( void);

void abort( void);


#ifdef DEBUG_ON

   void putchar( char);

/* there are other dump_xxx functions to add */

#endif

#endif // CORE_LIBRARY_C_STUBS_H