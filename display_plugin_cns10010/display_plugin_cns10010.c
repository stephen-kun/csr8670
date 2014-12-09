/*************************************************************************
Copyright © CSR plc 2012-2014
Part of ADK 3.5

FILE
    display_plugin_cns10010.c
    
DESCRIPTION
    Display plugin supporting the CNS10010 development board
    
    The hardware has a two-line, sixteen-character LCD on the I²C bus
    We make the first line and eight characters of the second line
    available for text, the remainder of the second line is used to
    show the volume and battery bars.
*/
#include <i2c.h>
#include <memory.h>
#include <display_plugin_if.h>
#include "display_plugin_cns10010_private.h"
#include "display_plugin_cns10010.h"

#define IIC_ADDRESS_LCD (0x3E)

#define DISPLAY_PLUGIN ((TaskData *) &display_plugin_cns10010)

static void message_handler(Task task, MessageId id, Message message);

const TaskData display_plugin_cns10010 = {message_handler};

static const lcd_datum lcd_setup_data[] = 
{
/*  Initialise LCD  */
    {RS_CTRL, LCD_CMD_DISPLAY | LCD_DISPLAY_OFF}, /* Turn off display */
    {RS_CTRL, LCD_CMD_CLEAR}, /* Clear display */
    {RS_CTRL, LCD_CMD_HOME}, /* Home cursor */
    {RS_CTRL, LCD_CMD_INSTRUCTION_SET | 1}, /* Instruction Set 1 */
    {RS_CTRL, LCD_CMD_FOLLOWER | 2}, /* Follower on; ratio 2 */
    {RS_CTRL, LCD_CMD_BOOSTER | 3}, /* Booster on; max contrast */
    {RS_CTRL, LCD_CMD_CONTRAST | 15}, /* Max contrast */
    {RS_CTRL, LCD_CMD_INSTRUCTION_SET | 0}, /* Instruction Set 0 */
    {RS_CTRL, LCD_CMD_ENTRY_MODE}, /* R-L cursor */    
    
/*  Set up user-defined characters  */
    {RS_CTRL, LCD_CMD_CGRAM}, /* Address CGRAM location 0 */
    
#define LCD_CHR_BATT (0)    
    {RS_DATA, 0x0E}, /* .###.     Char 0, battery icon (initially empty) */
    {RS_DATA, 0x1F}, /* ##### */
    {RS_DATA, 0x11}, /* #...# */
    {RS_DATA, 0x11}, /* #...# */
    {RS_DATA, 0x11}, /* #...# */
    {RS_DATA, 0x11}, /* #...# */
    {RS_DATA, 0x11}, /* #...# */
    {RS_DATA, 0x1F}, /* ##### */

#define LCD_CHR_VOL_LBR (1)        
    {RS_DATA, 0x01}, /* ....#     Char 1, volume bar left bracket */
    {RS_DATA, 0x01}, /* ....# */
    {RS_DATA, 0x01}, /* ....# */
    {RS_DATA, 0x01}, /* ....# */
    {RS_DATA, 0x01}, /* ....# */
    {RS_DATA, 0x01}, /* ....# */
    {RS_DATA, 0x01}, /* ....# */
    {RS_DATA, 0x01}, /* ....# */

#define LCD_CHR_VOL_0 (2)        
    {RS_DATA, 0x15}, /* #.#.#     Char 2, 0 bars */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x15}, /* #.#.# */
    
#define LCD_CHR_VOL_1 (3)        
    {RS_DATA, 0x15}, /* #.#.#     Char 3, 1 bar */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x15}, /* #.#.# */
    
#define LCD_CHR_VOL_2 (4)        
    {RS_DATA, 0x15}, /* #.#.#     Char 4, 2 bars */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x14}, /* #.#.. */
    {RS_DATA, 0x14}, /* #.#.. */
    {RS_DATA, 0x14}, /* #.#.. */
    {RS_DATA, 0x14}, /* #.#.. */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x15}, /* #.#.# */
    
#define LCD_CHR_VOL_3 (5)        
    {RS_DATA, 0x15}, /* #.#.#     Char 5, 3 bars */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x15}, /* #.#.# */
    {RS_DATA, 0x15}, /* #.#.# */
    {RS_DATA, 0x15}, /* #.#.# */
    {RS_DATA, 0x15}, /* #.#.# */
    {RS_DATA, 0x00}, /* ..... */
    {RS_DATA, 0x15}, /* #.#.# */
    
#define LCD_CHR_VOL_RBR (6)        
    {RS_DATA, 0x10}, /* #....     Char 6, volume bar right bracket */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x10}, /* #.... */
    {RS_DATA, 0x10}, /*.#.... */
    {RS_DATA, 0x10}, /*.#.... */
    
#define LCD_CHR_ANNUNCIATOR (7)        
    {RS_DATA, 0x00}, /* .....     Char 7, annunciator */
    {RS_DATA, 0x04}, /* ..#.. */
    {RS_DATA, 0x0E}, /* .###.*/
    {RS_DATA, 0x0A}, /* .#.#. */
    {RS_DATA, 0x0A}, /* .#.#. */
    {RS_DATA, 0x1F}, /* ##### */
    {RS_DATA, 0x04}, /* ..#.. */
    {RS_DATA, 0x00}, /* ..... */
    
/*  Address DDRAM line 2 col 9  */            
    {RS_CTRL, LCD_CMD_DDRAM | (LCD_DDRAM_LINE2 + 8)},
    
/*  Show bracketed volume bars (initially level 0)  */    
    {RS_DATA, LCD_CHR_VOL_LBR},
    {RS_DATA, LCD_CHR_VOL_0},
    {RS_DATA, LCD_CHR_VOL_0},
    {RS_DATA, LCD_CHR_VOL_0},
    {RS_DATA, LCD_CHR_VOL_0},
    {RS_DATA, LCD_CHR_VOL_0},
    {RS_DATA, LCD_CHR_VOL_RBR},
    
/*  Show battery icon  */
    {RS_DATA, LCD_CHR_BATT},
        
    {RS_END, 0}
};

static display_t *display;

static bool lcd_write(uint8 rs, uint8 data)
{
    uint16 ack;
    uint8 lcd_data[2];
    
    lcd_data[0] = rs;
    lcd_data[1] = data;
    
    ack = I2cTransfer(IIC_ADDRESS_LCD << 1, lcd_data, sizeof lcd_data, NULL, 0);
    DISPLAY_DEBUG(("cns10010: %02X %02X ack %d\n", lcd_data[0], lcd_data[1], ack));
    return ack == sizeof lcd_data + 1;
}


/*************************************************************************
NAME
    store_data
    
DESCRIPTION
    Put data in the buffer to be sent to the LCD when it's ready
*/
static void store_data(uint8 rs, uint8 data)
{
    display->lcd_buffer[display->buffer_idx].rs = rs;
    display->lcd_buffer[display->buffer_idx].data = data;
    ++display->buffer_idx;
    --display->buffer_space;
}


/*************************************************************************
NAME
    lcd_send_data
    
DESCRIPTION
    Send buffered data to the LCD
*/
static void lcd_send_data(void)
{
    while (display->buffer_space < LCD_BUFFER_SIZE)
    {
        lcd_write(display->lcd_buffer[display->buffer_odx].rs, display->lcd_buffer[display->buffer_odx].data);
        ++display->buffer_odx;
        ++display->buffer_space;
    }
}


/*************************************************************************
NAME
    lcd_send_init_data
    
DESCRIPTION
    Send next initialisation command to the LCD
*/
static void lcd_send_init_data(void)
{
    static const lcd_datum *dp;
        
    if (dp == NULL)
    {
        dp = lcd_setup_data;
        display->buffer_space = LCD_BUFFER_UNINIT;
    }
    
    if (dp->rs == RS_END)
    {
        MAKE_DISPLAY_MESSAGE(DISPLAY_PLUGIN_INIT_IND);
        DISPLAY_DEBUG(("cns10010: init done\n"));
        
    /*  Make circular buffer ready for data  */
        display->buffer_space = LCD_BUFFER_SIZE;
        
        message->result = TRUE;
        MessageSend(display->app_task, DISPLAY_PLUGIN_INIT_IND, message);
    }
    
    else
    {
        if (lcd_write(dp->rs, dp->data))
        {
            ++dp;
            MessageSendLater(DISPLAY_PLUGIN, LCD_SEND_INIT_DATA, NULL, LCD_COMMAND_TIME);
        }

        else
        {
            MAKE_DISPLAY_MESSAGE(DISPLAY_PLUGIN_INIT_IND);
            DISPLAY_DEBUG(("cns10010: init fail\n"));
        
            message->result = FALSE;
            MessageSend(display->app_task, DISPLAY_PLUGIN_INIT_IND, message);
        }
    }
}


/*************************************************************************
NAME
    display_init
    
DESCRIPTION
    Allocate and initialise display control structure
    Send data to initialise LCD after setup time
*/
static void display_init(DISPLAY_PLUGIN_INIT_MSG_T *msg)
{
    bool ok = (display == NULL);
         
    DISPLAY_DEBUG(("cns10010: init\n"));
             
    if (ok)
    {
        display = malloc(sizeof (display_t));
        ok = (display != NULL);
    }
    
    if (ok)
    {
        memset(display, 0, sizeof (display_t));
        display->app_task = msg->app_task;
#ifdef ENABLE_SCROLL
        *msg->max_length = LCD_LINE_LENGTH_1 * 2;
#else        
        *msg->max_length = LCD_LINE_LENGTH_1;
#endif        
        MessageSendLater(DISPLAY_PLUGIN, LCD_SEND_INIT_DATA, NULL, LCD_SETUP_TIME);
        DISPLAY_DEBUG(("cns10010: init OK\n"));
    }
        
    else
    {
        MAKE_DISPLAY_MESSAGE(DISPLAY_PLUGIN_INIT_IND);
        message->result = FALSE;
        MessageSend(msg->app_task, DISPLAY_PLUGIN_INIT_IND, message);
        DISPLAY_DEBUG(("cns10010: init failed\n"));
    }
}


/*************************************************************************
NAME
    lcd_display_text
    
DESCRIPTION
    Set the displayed text, padded with spaces
*/
static bool lcd_display_text(char* text, uint8 len, uint8 line)
{    
    uint16 txtlen = len;
    uint16 maxlen;
    uint8 start;
    
    DISPLAY_DEBUG(("cns10010: text %d on %d\n", txtlen, line));
    
    if(display->buffer_space == LCD_BUFFER_UNINIT)
    {
        DISPLAY_DEBUG(("cns10010: Text - LCD not yet init.\n"));
        return FALSE;
    }

    if (line == 1)
    {
        maxlen = LCD_LINE_LENGTH_1;
        start = LCD_CMD_DDRAM | LCD_DDRAM_LINE1;
    }
    
    else if (line == 2)
    {
        maxlen = LCD_LINE_LENGTH_2;
        start = LCD_CMD_DDRAM | LCD_DDRAM_LINE2;
    }

    else
        return FALSE;
        
    /* check the length of the line currently selected */
    if (txtlen > maxlen)
        txtlen = maxlen;
            
    /*  Need buffer space for cursor position command plus text  */
    if (txtlen + 1 > display->buffer_space)
    {
        DISPLAY_DEBUG(("cns10010: Text - BUFFER FULL\n"));
        return FALSE;
    }
        
    {
        uint16 idx;
        store_data(RS_CTRL, start); /* Address DDRAM, selecting the correct line  */
        
        for (idx = 0; idx < maxlen; ++idx)
        {
            if (idx < txtlen)
                store_data(RS_DATA, *text++);            
            else /* pad with spaces */
                store_data(RS_DATA, ' ');        
        }
        
        MessageSendLater(DISPLAY_PLUGIN, LCD_SEND_DATA, NULL, LCD_COMMAND_TIME);
        
        return TRUE;
    }
}

/*************************************************************************
NAME
    lcd_set_text
    
DESCRIPTION
    Store all the text for scrolling
*/

static void lcd_set_text(DISPLAY_PLUGIN_SET_TEXT_MSG_T *message)
{ 
    uint16 displayDuration = message->display_time;
#ifdef ENABLE_SCROLL
    uint8 maxLen;
    uint16 scrollLen = message->text_length;
    uint8 updateTime = message->scroll_update;
    uint8 scrollStartIn = message->scroll_pause;
    char *scrollBuffer = message->text;
    uint8 line = message->line;
       
    /* find the line lengths, cancel existing messages */
    if (line == 1)
    {
        MessageCancelAll(DISPLAY_PLUGIN, LCD_CLEAR_LINE1_MSG);
        MessageCancelAll(DISPLAY_PLUGIN, LCD_SCROLL_TEXT_LINE1_MSG);
        maxLen = LCD_LINE_LENGTH_1;       
    }
    else if (line == 2)
    {
        MessageCancelAll(DISPLAY_PLUGIN, LCD_CLEAR_LINE2_MSG);
        MessageCancelAll(DISPLAY_PLUGIN, LCD_SCROLL_TEXT_LINE2_MSG);                
        maxLen = LCD_LINE_LENGTH_2;     
    }
    else
        return;
             
    DISPLAY_DEBUG(("cns10010: line:%u, max:%u,  scrolllen:%u\n", line, maxLen, scrollLen ));        
    
    /* check if scrolling is needed */    
    if((message->scroll == DISPLAY_TEXT_SCROLL_SCROLL) && scrollLen > maxLen)
    {
        DISPLAY_DEBUG(("cns10010: Start Scrolling\n"));
           
        {
            /* All Scroll update messages are defined the same */
            MAKE_DISPLAY_MESSAGE_WITH_LEN( LCD_SCROLL_TEXT_MSG, scrollLen ) ; 

            message->text_length = scrollLen;
            message->scroll_update = updateTime;
            message->pos = 0;
            memmove(message->text,scrollBuffer,scrollLen) ;            
            
            if (line == 1)
            {
                MessageSendLater ( DISPLAY_PLUGIN, LCD_SCROLL_TEXT_LINE1_MSG, message, scrollStartIn ) ;    
            }
            else if (line == 2)
            {
                MessageSendLater ( DISPLAY_PLUGIN, LCD_SCROLL_TEXT_LINE2_MSG, message, scrollStartIn ) ;  
            }
            else
                Panic();
                
        }
    }
    else
    {
        DISPLAY_DEBUG(("cns10010: No Scrolling Needed\n"));
    }
    
#else
    /* if not scrolling only need to cancel existing clear messages */
    if (message->line == 1)
    {
        MessageCancelAll(DISPLAY_PLUGIN, LCD_CLEAR_LINE1_MSG);     
    }
    else if (message->line == 2)
    {
        MessageCancelAll(DISPLAY_PLUGIN, LCD_CLEAR_LINE2_MSG); 
    }
    else
        return;        
#endif

    /* display the text, this maybe the start of scrolling.  If not scrolling this is all that's required */
    if(!lcd_display_text(message->text,message->text_length, message->line))
        return;

    /* check if this text should be displayed for a limited time only */
    if (displayDuration && message->text_length > 0)
    {
        DISPLAY_DEBUG(("cns10010: clearing line %u in %u \n", message->line, displayDuration));     
        
        /* create message to clear the line */
        if (message->line == 1)
        {
            MessageSendLater ( DISPLAY_PLUGIN, LCD_CLEAR_LINE1_MSG, 0, displayDuration*1000 ) ;    
        }
        else if (message->line == 2)
        {
            MessageSendLater ( DISPLAY_PLUGIN, LCD_CLEAR_LINE2_MSG, 0, displayDuration*1000 ) ;  
        }
        else
            Panic();       
    }
}


/*************************************************************************
NAME
    lcd_scroll_text
    
DESCRIPTION
    Scroll the text 
*/
#ifdef ENABLE_SCROLL
static void lcd_scroll_text(LCD_SCROLL_TEXT_MSG_T *message, uint8 line)
{    
    uint16 scrollLen = message->text_length;   
    uint8 updateTime =    message->scroll_update;
    char *scrollBuffer = message->text;
    uint8 position = message->pos;
    
    DISPLAY_DEBUG(("cns10010: Scrolling (pos %u, scrllen %u, seglen %u)...\n", position, scrollLen, scrollLen-position));
 
    lcd_display_text(message->text+position,scrollLen-position, line);      

    /* jump back to the start if at the end of the text */
    if(scrollLen <= position)
        position = 0;
    else
        ++position;


    {
        /* create message to update scroll */
        MAKE_DISPLAY_MESSAGE_WITH_LEN( LCD_SCROLL_TEXT_MSG, scrollLen ) ; 

        message->text_length = scrollLen;
        message->scroll_update = updateTime;
        message->pos = position;
        
        memmove(message->text,scrollBuffer,scrollLen) ;   
        
        if (line == 1)
            MessageSendLater ( DISPLAY_PLUGIN, LCD_SCROLL_TEXT_LINE1_MSG, message, updateTime ) ;   
        else if (line == 2)
            MessageSendLater ( DISPLAY_PLUGIN, LCD_SCROLL_TEXT_LINE2_MSG, message, updateTime ) ;  
        else /* internal message, should never get here */
            Panic();           
    } 
}
#endif

/*************************************************************************
NAME
    lcd_clear_line
    
DESCRIPTION
    Internal message handler to clear display text line after a time out
*/
static void lcd_clear_line( uint16 line )
{
    DISPLAY_DEBUG(("cns10010: clear line %u\n", line));
    
#ifdef ENABLE_SCROLL    
    /*  cancel existing scroll messages */
    if (line == 1)
    {
        MessageCancelAll(DISPLAY_PLUGIN, LCD_SCROLL_TEXT_LINE1_MSG);
    }
    else if (line == 2)
    {
        MessageCancelAll(DISPLAY_PLUGIN, LCD_SCROLL_TEXT_LINE2_MSG);
    }
#endif        
    
    lcd_display_text("",0,line);
}



/*************************************************************************
NAME
    lcd_set_battery
    
DESCRIPTION
    Show the battery level by changing the graphic to have the
    appropriate number of bars
*/
static void lcd_set_battery(uint16 battery_level)
{    
    DISPLAY_DEBUG(("cns10010: batt %d\n", battery_level));

    if(display->buffer_space == LCD_BUFFER_UNINIT)
    {
        DISPLAY_DEBUG(("cns10010: batt - LCD not yet init.\n"));
        return;
    }
    
/*  Need space for control plus eight rows of icon data  */
    if (display->buffer_space < 9)
    {
        DISPLAY_DEBUG(("cns10010: Batt - BUFFER FULL\n"));
    }
    
    else
    {
        uint16 level;

        store_data(RS_CTRL, LCD_CMD_CGRAM); /* Address CGRAM char 0 */
        
        store_data(RS_DATA, 0x0E); /* Battery icon  .###.*/
        store_data(RS_DATA, 0x1F); /* Battery icon  ##### */
        
        /* if on charge display a 'C' in the battery */
        if(battery_level == 0xff)
        {
            store_data(RS_DATA, 0x11); /*       #...# */
            store_data(RS_DATA, 0x17); /*       #.### */
            store_data(RS_DATA, 0x17); /*       #.### */
            store_data(RS_DATA, 0x17); /*       #.### */
            store_data(RS_DATA, 0x11); /*       #...# */
        }
        else
        {
            for (level = 5; level; --level)
            {
                if (level > battery_level)
                    store_data(RS_DATA, 0x11); /*       #...# */
                
                else
                    store_data(RS_DATA, 0x1F); /*       ##### */            
            }
        }
        
        store_data(RS_DATA, 0x1F); /* Battery icon  ##### */
        MessageSendLater(DISPLAY_PLUGIN, LCD_SEND_DATA, NULL, LCD_COMMAND_TIME);
    }
}


/*************************************************************************
NAME
    lcd_set_volume
    
DESCRIPTION
    Show the volume level
*/
static void lcd_set_volume(uint16 volume)
{
    DISPLAY_DEBUG(("cns10010: vol %d\n", volume));
    
    if(display->buffer_space == LCD_BUFFER_UNINIT)
    {
        DISPLAY_DEBUG(("cns10010: vol - LCD not yet init.\n"));
        return;
    }    

/*  Need space for cursor control plus five part-bar characters */
    if (display->buffer_space < 6)
    {
        DISPLAY_DEBUG(("cns10010: Vol - BUFFER FULL\n"));
    }
    
    else
    {
        uint16 level;
        
    /*  Position cursor  */
        store_data(RS_CTRL, LCD_CMD_DDRAM | (LCD_DDRAM_LINE2 + 9));
        
    /*  Build volume bar from groups of 0, 1, 2 or 3  */
        for (level = 1; level <= DISPLAY_MAX_VOLUME; level += 3)
        {
            uint8 bar;
            
            if (volume < level)
                bar = LCD_CHR_VOL_0;
            
            else if (volume == level)
                bar = LCD_CHR_VOL_1;
            
            else if (volume - level == 1)
                bar = LCD_CHR_VOL_2;
            
            else
                bar = LCD_CHR_VOL_3;
            
            store_data(RS_DATA, bar);
        }

        MessageSendLater(DISPLAY_PLUGIN, LCD_SEND_DATA, NULL, LCD_COMMAND_TIME);
    }
}


/*************************************************************************
NAME
    lcd_set_state
    
DESCRIPTION
    Set the LCD state (off or on)
*/
static void lcd_set_state(DISPLAY_PLUGIN_SET_STATE_MSG_T *message)
{
    DISPLAY_DEBUG(("cns10010: state %d\n", message->state));

     if(display->buffer_space == LCD_BUFFER_UNINIT)
    {
        DISPLAY_DEBUG(("cns10010: state - LCD not yet init.\n"));
        return;
    }   
    
    if (display->buffer_space < 1)
    {
        DISPLAY_DEBUG(("cns10010: State - BUFFER FULL\n"));
    }
    
    else
    {
        store_data(RS_CTRL, message->state ?
                   LCD_CMD_DISPLAY | LCD_DISPLAY_ON :
                   LCD_CMD_DISPLAY | LCD_DISPLAY_OFF);

        MessageSendLater(DISPLAY_PLUGIN, LCD_SEND_DATA, NULL, LCD_COMMAND_TIME);
    }
}



/*************************************************************************
NAME
    message_handler
    
DESCRIPTION
    Handle internal and display library messages
*/
static void message_handler (Task task, MessageId id, Message message)
{
    DISPLAY_DEBUG(("cns10010: msg %04X\n", id));
    
    switch (id)
    {
    case LCD_SEND_INIT_DATA:
        lcd_send_init_data();
        break;
        
    case LCD_SEND_DATA:
        lcd_send_data();
        break;     
        
#ifdef ENABLE_SCROLL        
    case LCD_SCROLL_TEXT_LINE1_MSG:
        lcd_scroll_text((LCD_SCROLL_TEXT_MSG_T *) message, 1);   
        break;
        
    case LCD_SCROLL_TEXT_LINE2_MSG:
        lcd_scroll_text((LCD_SCROLL_TEXT_MSG_T *) message, 2);   
        break;        
#endif        

    case LCD_CLEAR_LINE1_MSG:
        lcd_clear_line(1);
        break;
        
    case LCD_CLEAR_LINE2_MSG:
        lcd_clear_line(2);
        break;
        
    case DISPLAY_PLUGIN_INIT_MSG:
        display_init((DISPLAY_PLUGIN_INIT_MSG_T *) message);
        break;
        
    case DISPLAY_PLUGIN_SET_STATE_MSG:
        lcd_set_state((DISPLAY_PLUGIN_SET_STATE_MSG_T *) message);
        break;
        
    case DISPLAY_PLUGIN_SET_TEXT_MSG:
        lcd_set_text((DISPLAY_PLUGIN_SET_TEXT_MSG_T *) message);      
        break;
    
    case DISPLAY_PLUGIN_SET_BATTERY_MSG:
        {
            DISPLAY_PLUGIN_SET_BATTERY_MSG_T *m = (DISPLAY_PLUGIN_SET_BATTERY_MSG_T *) message;
            lcd_set_battery(m->battery_level);
        }
        break;
        
    case DISPLAY_PLUGIN_SET_VOLUME_MSG:
        {
            DISPLAY_PLUGIN_SET_VOLUME_MSG_T *m = (DISPLAY_PLUGIN_SET_VOLUME_MSG_T *) message;
            lcd_set_volume(m->volume);
        }
        break;
        
    case DISPLAY_PLUGIN_SET_ICON_MSG:
    /*  Not supported  */
        break;
    }
}
