/*****************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2012-2014
*/

#ifdef DEBUG_DISPLAY
#include <stdio.h>
#include <panic.h>
#define DISPLAY_DEBUG(X) printf X
#define DISPLAY_PANIC() Panic()
#else
#define DISPLAY_DEBUG(X)
#define DISPLAY_PANIC()
#endif

#ifndef NULL
#define NULL ((void *) 0)
#endif

#define RS_CTRL (0x00)
#define RS_DATA (0x40)
#define RS_END (0xFF)

#define LCD_BUFFER_SIZE (32)

/* ST7032 LCD conroller commands */
#define LCD_CMD_CLEAR (0x01)
#define LCD_CMD_HOME (0x02)
#define LCD_CMD_ENTRY_MODE (0x06)
#define LCD_CMD_DISPLAY (0x08)
#define LCD_CMD_CGRAM (0x40)
#define LCD_CMD_DDRAM (0x80)

#define LCD_CMD_INSTRUCTION_SET (0x28)
#define LCD_CMD_FOLLOWER (0x68)
#define LCD_CMD_BOOSTER (0x54)
#define LCD_CMD_CONTRAST (0x70)

#define LCD_DISPLAY_OFF (0x00)
#define LCD_DISPLAY_ON (0x04)

#define LCD_DDRAM_LINE1 (0x00)
#define LCD_DDRAM_LINE2 (0x40)

/*  Times to execute commands based on ST7032 with 380kHz clock*/
#define LCD_SETUP_TIME (50)
#define LCD_COMMAND_TIME (1)

/* the usuable text length of the display, line 2 shorter because of icon area */
#define LCD_LINE_LENGTH_1 (16)
#define LCD_LINE_LENGTH_2 (8)

#define DISPLAY_MAX_VOLUME (15)


/*!
    @brief Internal message in the display plugin to scroll update 
    the scrolling text on the display
*/
typedef struct 
{
    /*! current position in the string */
    uint8           pos;
     /*! amount of time in ms before the display scroll updates */
    uint16          scroll_update;
       /*!length of the text to display*/
    uint8           text_length;
       /*! text to display */
    char            text[1];
}LCD_SCROLL_TEXT_MSG_T ;

#define LCD_SCROLL_TEXT_LINE1_MSG_T LCD_SCROLL_TEXT_MSG_T
#define LCD_SCROLL_TEXT_LINE2_MSG_T LCD_SCROLL_TEXT_MSG_T

enum
{
    LCD_SEND_INIT_DATA = 1,
    LCD_SEND_DATA,
    LCD_SCROLL_TEXT_LINE1_MSG,
    LCD_SCROLL_TEXT_LINE2_MSG,
    LCD_CLEAR_LINE1_MSG,
    LCD_CLEAR_LINE2_MSG
} cns10010_internal_message_t;

typedef struct
{
    unsigned rs:8;
    unsigned data:8;
} lcd_datum;

typedef struct
{
    TaskData *app_task;
    unsigned buffer_idx:5;
    unsigned buffer_odx:5;
    unsigned buffer_space:6;
    lcd_datum lcd_buffer[LCD_BUFFER_SIZE];          
} display_t;

#define LCD_BUFFER_UNINIT 0x3f


