/*************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2012

FILE
    fm_rx_plugin.c
    
DESCRIPTION
    FM RX plugin supporting the CNS10010 development board
    
    The hardware has a two-wire, 3- wire FM RX on the I²C bus
*/
#include <i2c.h>
#include <memory.h>
#include "fm_plugin_if.h"
#include "fm_rx_plugin.h"
#include "fm_rx_plugin_private.h"
#include "pio.h"
#include "ps.h"
#include "source.h"
#include "sink.h"
#include "stdio.h"

/* the FM receiver I2C bus address for control messages to be sent to */
#define IIC_ADDRESS_FM_RX ((0x11) << 1)

#define gFmRxPlugInTask ((TaskData *) &fm_rx_plugin)

static void message_handler(Task task, MessageId id, Message message);

const TaskData fm_rx_plugin = {message_handler};

/* list of opcodes that are sent to the FM receiver chip to initialise the tuning parameters */
static const uint16 fm_rx_opcode[(sizeof(fm_rx_config))] =
{
    FM_SEEK_BAND_BOTTOM, /* seek_band_bottom*//*88.1 Mhz*/
    FM_SEEK_BAND_TOP, /* seek_band_top *//*107.9  Mhz*/
    FM_SEEK_FREQ_SPACING, /* freq_spacing*/
    FM_SEEK_TUNE_RSSI_THRESHOLD, /* seek_tune_rssi */
    FM_SEEK_TUNE_SNR_THRESHOLD, /* seek_tune_snr*/
    FM_RSQ_RSSI_LO_THRESHOLD, /* rsq_rssi_low */
    FM_RSQ_RSSI_HI_THRESHOLD, /* rsq_rssi_high*/
    FM_RSQ_SNR_LO_THRESHOLD, /* rsq_snr_low */
    FM_RSQ_SNR_HI_THRESHOLD, /* rsq_snr_high */
    FM_ANTENNA_INPUT, /* antenna selection */
    FMRX_END
};

static const char *pProgramType[MAX_NUM_PROGRAM_TYPE]=
{
    "    ",
    "News",
    "Affairs",
    "Info",
    "Sport",
    "Educate",
    "Drama",
    "Culture",
    "Science",
    "Varied",
    "Pop M",
    "Rock M",
    "Easy M",
    "Light M",
    "Classics",
    "Other M"
};

    
/*Global FM RX data structure*/
static fm_rx_data_t *fm_rx_data;


/****************************************************************************
NAME 
    fm_rx_reset_low
    
DESCRIPTION
    Setting the RST pin low will disable analog and digital
    circuitry, reset the registers to their default settings, and
    disable the bus. Setting the RST pin high will bring the
    device out of reset.
    
RETURNS
    void
*/ 
static void fm_rx_reset_low(void)
{
    FM_DEBUG(("fm_rx_reset_low \n"));
    PioSetDir32((1<<fm_rx_data->config.hardware_pio), (1<<fm_rx_data->config.hardware_pio)); 
    PioSet32((1<<fm_rx_data->config.hardware_pio), 0 ); 
}

/****************************************************************************
NAME 
    fm_rx_reset_high
    
DESCRIPTION
    Setting the RST pin low will disable analog and digital
    circuitry, reset the registers to their default settings, and
    disable the bus. Setting the RST pin high will bring the
    device out of reset.
    
RETURNS
    void
*/ 
static void fm_rx_reset_high(void)
{
    FM_DEBUG(("fm_rx_reset_high \n"));
    PioSetDir32((1<<fm_rx_data->config.hardware_pio), (1<<fm_rx_data->config.hardware_pio)); 
    PioSet32((1<<fm_rx_data->config.hardware_pio), (1<<fm_rx_data->config.hardware_pio));  
}

/****************************************************************************
NAME 
    fm_rx_write_command
    
DESCRIPTION
    function to perform an I2C write of command data the the FM receiver chip,
    data command and size parameters passed in
    

RETURNS
    status of command operation
*/ 
static bool fm_rx_write_command(uint8 *fm_data, uint8 size)
{        
    uint16 ack;
    uint8 Id;
    FM_ASSERT(fm_data);
                     
    ack = I2cTransfer(FM_RX_IIC_ADDRESS, fm_data, size, NULL, 0);
    FM_DEBUG(("fm_rx_write_command: ack %d\n", ack));

    for (Id=0;Id<size; Id++)
    {
        FM_DEBUG((" Byte[%d]=0x%X \n", Id, fm_data[Id]));
    }

    return (ack == size + 1);
}

/****************************************************************************
NAME 
    fm_rx_write_prop
    
DESCRIPTION
    function to perform an I2C write of property data the the FM receiver chip,
    property id and property value are parameters passed in
    

RETURNS
    status of write property operation
*/ 
static bool fm_rx_write_prop(uint16 prop, uint16 value)
{        
    uint16 ack;
    uint8 fm_data[6];

    FMSETPROP(fm_data, prop);
    fm_data[4] = HIGHBYTE(value);
    fm_data[5] = LOWBYTE(value);
                     
    ack = I2cTransfer(FM_RX_IIC_ADDRESS, fm_data, 6, NULL, 0);     
    FM_DEBUG(("fm_rx_write_prop: Ack %d, Property - %02X %02X, Value - %02X %02X \n", 
    ack, fm_data[2], fm_data[3], fm_data[4], fm_data[5]));
    return (ack == sizeof fm_data + 1);
}

/****************************************************************************
NAME 
    fm_rx_power_up
    
DESCRIPTION
    function to send the POWER_UP command to the FM receiver chip    

RETURNS
    status of send POWER_UP command operation
*/ 
static bool fm_rx_power_up(void)
{        
    uint8 fm_data[FMRX_POWER_UP_LEN];

    FM_DEBUG(("fm_rx_power_up\n"));

    fm_data[0] = FMRX_POWER_UP;
    fm_data[1]=  0xC0; /*GPO2 Output Enable, CTS Interrupt Enable.*/
    fm_data[2]=  0xB0;  /* digital output */

    return (fm_rx_write_command(fm_data, FMRX_POWER_UP_LEN));
}



/****************************************************************************
NAME 
    fm_rx_power_down
    
DESCRIPTION
    Powerdown mode is available to reduce power
    consumption when the part is idle. Putting the device in
    powerdown mode will disable analog and digital circuitry
    while keeping the bus active.    
    
RETURNS
    void
*/ 
static void fm_rx_power_down(void)
{
    uint8 fm_data[1];

    FM_DEBUG(("fm_rx_power_down \n")); 
    fm_data[0] = FMRX_POWER_DOWN;
    fm_rx_write_command(fm_data, 1);

    /*FmRx clean up*/
    FM_ASSERT(fm_rx_data);
    if (fm_rx_data->rds_data.program_service)
        free(fm_rx_data->rds_data.program_service);
    if (fm_rx_data->rds_data.radio_text)
        free(fm_rx_data->rds_data.radio_text);
    fm_rx_data=NULL;
}

/****************************************************************************
NAME 
    fm_rx_update_volume
    
DESCRIPTION
    updates the volume output from the FM receiver chip    

RETURNS
    void
*/ 
static void fm_rx_update_volume(FM_PLUGIN_RX_UPDATE_VOLUME_MSG_T * msg)
{    
    uint16 prop;
    uint16 vol=msg->volume;
    
    FM_DEBUG(("fm_rx_update_volume %d\n", vol));

    if (msg->volume > 0)
    {
        prop=RX_VOLUME;
        
        if (vol>FMRX_DEFAULT_VOLUME)
        {
            vol=FMRX_DEFAULT_VOLUME;
        }
    }
    else
    {
        prop=RX_HARD_MUTE;
        vol=FM_RX_MUTE;
    }

    /*Write property to FM chip*/
    fm_rx_write_prop(prop, vol);
    
}

/****************************************************************************
NAME 
    fm_rx_get_rev
    
DESCRIPTION
    Function to obtain the Part number and firmware revisions from the FM reciver chip
    
RETURNS
    void
*/ 
static void fm_rx_get_rev(void)
{        
    uint16 ack;
    uint8 count;
    uint8 fm_data[1];

    FM_DEBUG(("fm_rx_get_rev\n"));

    fm_data[0] = FMRX_GET_REV;

    memset(fm_rx_data->rx_buff, 0, FMRX_MAX_BUFFER_SIZE);
    ack = I2cTransfer(FM_RX_IIC_ADDRESS , fm_data, 1, fm_rx_data->rx_buff, FMRX_GET_REV_LEN);
    
    for(count=0; count < FMRX_GET_REV_LEN; count++)
    {
        FM_DEBUG(("FM RX REVISION Byte[%d]=0x%x \n", count, fm_rx_data->rx_buff[count]));
    }
}



/****************************************************************************
NAME 
    fm_rx_check_tune_status
    
DESCRIPTION
    function to check whether the FM receiver chip has successfully tuned to a channel,
    this function checks the interrupt status bit for tune_complete and when set then
    goes on to check whether the chip successfully tuned to a channel or just gave up    
    
RETURNS
    void
*/ 
static void fm_rx_check_tune_status(void)
{
    uint8 cmd[2];
    uint16 ack = 0;
#ifdef DEBUG_FM
    uint16 count = 0;
#endif

    FM_ASSERT(fm_rx_data);

    /* check the TUNE COMPLETE interrupt status bit */
    cmd[0] = FMRX_GET_INT_STATUS;
    memset(fm_rx_data->rx_buff, 0, FMRX_MAX_BUFFER_SIZE);

    {                
        ack = I2cTransfer(FM_RX_IIC_ADDRESS , cmd, 1, fm_rx_data->rx_buff, 1);        
        FM_DEBUG(("fm_rx_check_tune_status: ack %d value 0x%x \n", ack, fm_rx_data->rx_buff[0]));
    }        
    
    /* check the TUNE COMPLETE interrupt status bit */
    if(fm_rx_data->rx_buff[0] & 0x01) /*STCINT high*/
    {
        uint16 tuned_freq=0;
        
        cmd[0] = FMRX_FM_TUNE_STATUS;
        cmd[1] = 0x01; /*INTACK - Seek/Tune Interrupt Clear. */
 
        /* the tune complete interrupt bit is set, now check the tune status information */
        ack = I2cTransfer(FM_RX_IIC_ADDRESS , cmd, 2, fm_rx_data->rx_buff, 7);
        FM_DEBUG(("fm_rx_check_tune_status %d \n", ack));

        /* Attempt to obtain the frequency currently tuned to */
        tuned_freq = ((fm_rx_data->rx_buff[2]<<8)|(fm_rx_data->rx_buff[3]));

        /* if tuned successfully then store the retrieved frequency */        
        if (tuned_freq!=0x0000)
        {
            fm_rx_data->currently_tuned_freq=tuned_freq;
            FM_DEBUG((" Currently Tuned Frequency (0x%x) (%d) \n", tuned_freq, tuned_freq));

            /* Initiate RDS*/
            /* Before that Cancel previous RDS requests*/
            MessageCancelAll(gFmRxPlugInTask, FMRX_RDS_STATUS_MSG);
            MessageCancelAll(gFmRxPlugInTask, FMRX_RDS_CANCEL_MSG);
            MessageSendLater(gFmRxPlugInTask, FMRX_RDS_INITIATE_MSG, NULL, FM_COMMAND_CTS_DELAY);
        }        

        /*Send indication to headset/sink app*/
        {
            MAKE_FM_MESSAGE(FM_PLUGIN_TUNE_COMPLETE_IND);
            message->result = TRUE;
            message->tuned_freq = fm_rx_data->currently_tuned_freq;
            MessageSend(fm_rx_data->app_task, FM_PLUGIN_TUNE_COMPLETE_IND, message);
        }

#ifdef DEBUG_FM
        for(count=0; count < 8; count++)
        {
            FM_DEBUG(("fm_rx_check_tune_status Byte:%d  Value:0x%x \n", count, fm_rx_data->rx_buff[count]));
        }
#endif
    }
    /* tuning not yet completed, reschedule another check in 120mS time */
    else
    {
         MessageSendLater (gFmRxPlugInTask, FMRX_TUNE_STATUS_MSG, NULL, FM_TUNE_CTS_DELAY);
    }
}


/*************************************************************************
NAME
    fm_rx_init_rds
    
DESCRIPTION
    Initialise FM RX RDS control structure.
    Allocate for program service and radio text RDS information
RETURNS
    void

*/
static void fm_rx_init_rds(void)
{
    FM_ASSERT(fm_rx_data);
    fm_rx_data->rds_data.program_code=0xFF; 
}


/*************************************************************************
NAME
    fm_rx_alloc_rds_buff
    
DESCRIPTION
    One time allocation for program service and radio text RDS information during init
    and free during poweroff. One byte extra is for string termination
RETURNS
    void

*/
static void fm_rx_alloc_rds_buff(void)
{
    /* initialise the rds data buffers */
    memset(&fm_rx_data->rds_data, 0, (sizeof(fm_rds_data)));
    
    /*Allocate for rds program service data */
    fm_rx_data->rds_data.program_service = PanicUnlessMalloc(MAX_PROGRAM_SERVICE+1);
    memset(fm_rx_data->rds_data.program_service, 0, (MAX_PROGRAM_SERVICE+1));
    
    /*Allocate for rds radio text data*/
    fm_rx_data->rds_data.radio_text= PanicUnlessMalloc(MAX_RADIO_TEXT+1);
    memset(fm_rx_data->rds_data.radio_text, 0, (MAX_RADIO_TEXT+1));
}

/****************************************************************************
NAME 
    fm_rx_decode_program_service
    
DESCRIPTION
    function to decode program service - 
    Decodes block B(control) and block D(data) for program service
    
RETURNS
    void
*/ 
static void fm_rx_decode_program_service(uint8 *pRx_rds, fm_rds_data *pGlobal_rds)
{    
    /*Address type is last two bits of Response byte 7 for PS*/
    uint8 ps_addr=(pRx_rds[BLKB_INDEX+1]&PS_ADDR_MASK);

    if (ps_addr != 0xFF)
    {
        if ((fm_rx_data->rds_data.ps_bitmask & 0x0F) == 0x0F)
        {
            fm_rx_data->rds_data.ps_bitmask = 0;
            memset(pGlobal_rds->program_service, 0, (MAX_PROGRAM_SERVICE+1));
        }

        /* If this is the first name we just accept the packages as they are coming
        After the first result we start storing blocks in sequences starting from address 0x00 */
        if ((fm_rx_data->rds_data.ps_valid==FALSE ||(fm_rx_data->rds_data.ps_bitmask || (ps_addr == 0))))
        {
            fm_rx_data->rds_data.program_service[ps_addr * PS_ADDR_OFFSET] = fm_rx_data->rx_buff[BLKD_INDEX];
            fm_rx_data->rds_data.program_service[(ps_addr * PS_ADDR_OFFSET) + 1] = fm_rx_data->rx_buff[BLKD_INDEX+1];
            FM_DEBUG(("program service found %s  \n", fm_rx_data->rds_data.program_service));

            fm_rx_data->rds_data.ps_bitmask |= 0x01 << ps_addr;
            if ((fm_rx_data->rds_data.ps_bitmask & 0x0F) == 0x0F)
            {
                FM_DEBUG(("program service name complete  \n"));

                /* If this is the first time we have received the name, we need to clear the chars for 
                   addresses larger than the current to correct potential name change errors. 
                   (If a name change occured during the reception.)*/
                if(fm_rx_data->rds_data.ps_valid == FALSE)
                {
                    FM_DEBUG(("program service name change  \n"));

                    for(ps_addr++; ps_addr<4;ps_addr++)
                    {
                        fm_rx_data->rds_data.ps_bitmask &= ~(0x01 << ps_addr); 
                    }
                }

                fm_rx_data->rds_data.ps_valid = TRUE;                
                fm_rx_data->rds_data.program_service[MAX_PROGRAM_SERVICE] = '\0';

                {
                    MAKE_FM_MESSAGE_WITH_LEN(FM_PLUGIN_RDS_IND, MAX_PROGRAM_SERVICE+1);

                    message->rds_type=FMRX_RDS_PROGRAM_SERVICE;
                    message->data_len=MAX_PROGRAM_SERVICE+1;
                    memcpy(message->data, pGlobal_rds->program_service, MAX_PROGRAM_SERVICE+1);
                    MessageSend(fm_rx_data->app_task, FM_PLUGIN_RDS_IND, message);
                    FM_DEBUG(("Ps data %s \n", pGlobal_rds->program_service));
                }
            }
        }
    }

}

/****************************************************************************
NAME 
    fm_rx_decode_radio_text
    
DESCRIPTION
    function to decode the radio text data 
    Decodes block B(control) and block C (for type 0A) and D(for type 0A and 0B)

RETURNS
    void
*/ 

static void fm_rx_decode_radio_text(uint8 *pRx_rds, fm_rds_data *pGlobal_rds)
{                    
    uint8 bler=(pRx_rds[FMRX_MAX_RDS_BUFF_SIZE]);/*Block error rate*/

    /*BLOCK B - RESP 6 and RESP 7 processing*/    
    uint8 addr=(pRx_rds[BLKB_INDEX+1] & RT_ADDR_MASK);/*Address type is last four bits of Response byte 7*/
    uint8 rt_type=0;
    bool rt_done=FALSE;
    bool send_ind=FALSE;

    FM_ASSERT(pGlobal_rds->radio_text);
       
    if (pRx_rds[BLKB_INDEX] & GROUP_VARIANT_MASK)
    {
        rt_type = 0;/*Type 0B*/
    }
    else
    {
        rt_type = 1;/*Type 0A*/
    }

    if (((pRx_rds[BLKB_INDEX+1] & 0x10) >> 4) != fm_rx_data->rds_data.rt_abflag)
    {
        fm_rx_data->rds_data.rt_abflag = (uint8)((pRx_rds[BLKB_INDEX+1] & 0x10) >> 4);
        memset(pGlobal_rds->radio_text, 0, (MAX_RADIO_TEXT+1));
        fm_rx_data->rds_data.rt_bitmask = 0;
    }

    /*BLOCK C - RESP 8 and RESP 9 processing*/    
    if ((addr <= 0x0F) && ((bler&RDS_BLER_BLKC_MASK)!=RDS_BLER_UNCORRECTABLE))
    {
        uint8 rtOffset;
        uint8 i;
        uint8 rt_complete = TRUE;

        rtOffset = addr << (1 + rt_type);
        
        {
            if (pRx_rds[BLKC_INDEX] == 0x0D) /* Carriage return */
            {
                rt_done = TRUE;
                fm_rx_data->rds_data.radio_text[rtOffset] = '\0';
            }
            else
            {
                fm_rx_data->rds_data.radio_text[rtOffset] = pRx_rds[BLKC_INDEX];
                
                if ((pRx_rds[BLKC_INDEX+1] == 0x0D) || 
                    ((pRx_rds[BLKC_INDEX] == ' ') && (pRx_rds[BLKC_INDEX+1] == ' ')))
                {
                    rt_done = TRUE;
                    fm_rx_data->rds_data.radio_text[rtOffset+1] = '\0';
                }
                else
                {
                    fm_rx_data->rds_data.radio_text[rtOffset+1] = pRx_rds[BLKC_INDEX+1];
                }
            }
            
            fm_rx_data->rds_data.rt_bitmask |= (1 << (addr << 1));
            
            for (i = 0; i < 16; i++)
            {
                if (fm_rx_data->rds_data.rt_bitmask & (1 << i))
                {
                    if ((fm_rx_data->rds_data.radio_text[rtOffset] ==  '\0') ||
                        (fm_rx_data->rds_data.radio_text[rtOffset+1] == '\0'))
                    {
                        break;
                    }
                }
                else
                {
                    rt_complete = FALSE;
                    break;
                }
            }
            
            if (rt_complete)
            {                
                fm_rx_data->rds_data.radio_text[MAX_RADIO_TEXT] = '\0';
                FM_DEBUG(("BLKC: RT data %s \n", fm_rx_data->rds_data.radio_text));
                send_ind=TRUE;
            }
        }
    }

    /*BLOCK D - RESP 10 and RESP 11 processing*/    
    if ((addr <= 0x0F) && ((bler&RDS_BLER_BLKD_MASK)!=RDS_BLER_UNCORRECTABLE)
        && (!rt_done))
    {
        uint8 rtOffset;
        uint8 i;
        uint8 rt_complete = TRUE;

        rtOffset = (addr << (1 + rt_type)) + (rt_type << 1);

        {
            if (pRx_rds[BLKD_INDEX] == 0x0D)   /* Carriage return */
            {
                rt_done = TRUE;
                fm_rx_data->rds_data.radio_text[rtOffset] = '\0';
            }
            else
            {
                fm_rx_data->rds_data.radio_text[rtOffset] =  pRx_rds[BLKD_INDEX];
                
                if ((pRx_rds[BLKD_INDEX+1] == 0x0D) || 
                    ((pRx_rds[BLKD_INDEX] == ' ') && (pRx_rds[BLKD_INDEX+1] == ' ')))
                {
                    rt_done = TRUE;
                    fm_rx_data->rds_data.radio_text[rtOffset+1] = '\0';
                }
                else
                {
                    fm_rx_data->rds_data.radio_text[rtOffset+1]
                        = pRx_rds[BLKD_INDEX+1];
                }
            }

            fm_rx_data->rds_data.rt_bitmask |= (1 << ((addr << (rt_type)) + rt_type));
            
            for (i = 0; i < 16; i++)
            {
                if (fm_rx_data->rds_data.rt_bitmask & (1 << i))
                {
                    if ((fm_rx_data->rds_data.radio_text[rtOffset] ==  '\0') ||
                        (fm_rx_data->rds_data.radio_text[rtOffset+1] == '\0'))
                    {
                        break;
                    }
                }
                else
                {
                    rt_complete = FALSE;
                    break;
                }
            }

            if (rt_complete)
            {                
                fm_rx_data->rds_data.radio_text[MAX_RADIO_TEXT] = '\0';
                FM_DEBUG(("BLKD: RT data %s \n", fm_rx_data->rds_data.radio_text));
                send_ind=TRUE;
            }
        }
    }

    if (send_ind)
    {
        MAKE_FM_MESSAGE_WITH_LEN(FM_PLUGIN_RDS_IND, MAX_RADIO_TEXT+1);

        message->rds_type=FMRX_RDS_RADIO_TEXT;
        message->data_len=MAX_RADIO_TEXT+1;
        memcpy(message->data, pGlobal_rds->radio_text, MAX_RADIO_TEXT+1);
        MessageSend(fm_rx_data->app_task, FM_PLUGIN_RDS_IND, message);
        FM_DEBUG(("RT data sent to Headset app %s \n", pGlobal_rds->radio_text));
    }
}



/****************************************************************************
NAME 
    fm_rx_decode_rds
    
DESCRIPTION
    function to decode rds information according to the format given by FM chip.
    RDS status received from chip -

       Bit D7 D6 D5 D4 D3 D2 D1 D0
    STATUS CTS ERR X X RSQINT RDSINT X STCINT
    RESP1  X X RDSNEWBLOCKB RDSNEWBLOCKA X RDSSYNCFOUND RDSSYNCLOST RDSRECV
    RESP2  X X X X X GRPLOST X RDSSYNC
    RESP3  RDSFIFOUSED[7:0]
    RESP4  BLOCKA[15:8]
    RESP5  BLOCKA[7:0]
    RESP6  BLOCKB[15:8]
    RESP7  BLOCKB[7:0]
    RESP8  BLOCKC[15:8]
    RESP9  BLOCKC[7:0]
    RESP10 BLOCKD[15:8]
    RESP11 BLOCKD[7:0]
    RESP12 BLEA[1:0] BLEB[1:0] BLEC[1:0] BLED[1:0]

RETURNS
    void
*/ 
static void fm_rx_decode_rds(uint8 *pRx_rds, fm_rds_data *pGlobal_rds)
{          
    uint8 bler=(pRx_rds[FMRX_MAX_RDS_BUFF_SIZE]);/*Block error rate*/

    FM_ASSERT(pRx_rds);
    FM_ASSERT(pGlobal_rds);
    
    if ( (pRx_rds[1] & 0x01) /*RDS received*/
         &&(pRx_rds[2] & 0x01) /*RDS synchronised*/
         && (!(pRx_rds[2] & 0x04)) /*not RDS group lost*/
         && (pRx_rds[3] > 0) /*RDS FIFO greater than 0*/
       )
    {        
        /*Program Identification code in block A*/
        uint16 received_program_code=((pRx_rds[BLKA_INDEX]<<8)|(pRx_rds[BLKA_INDEX+1]));
        
        /*Stop RDS timeout msg as we started receiving RDS*/
        MessageCancelAll(gFmRxPlugInTask, FMRX_RDS_CANCEL_MSG);

        if ((pRx_rds[1]&RDSNEWBLOCKA_MASK)&&((bler&RDS_BLER_BLKA_MASK)==RDS_BLER_NO_ERROR))
        {
            /*init again if a valid block A is found*/
            fm_rx_init_rds();
            pGlobal_rds->program_code=received_program_code;
            pGlobal_rds->program_code_valid=TRUE;
            FM_DEBUG(("NEW BLK A received\n"));
        }

        if ((pGlobal_rds->program_code==received_program_code) &&
            (pGlobal_rds->program_code_valid) &&
            (pRx_rds[1]&RDSNEWBLOCKB_MASK) &&
            ((bler&RDS_BLER_BLKB_MASK)!=RDS_BLER_UNCORRECTABLE))
        {    
            /*Get the program type in block B - response 6 & 7 contains program type*/  
            uint16 program_type=((pRx_rds[BLKB_INDEX]&PROGRAM_TYPE_MASK1)<<PROGRAM_TYPE_OFFSET1)|
                                ((pRx_rds[BLKB_INDEX+1]&PROGRAM_TYPE_MASK2)>>PROGRAM_TYPE_OFFSET2);
            
            /*Get the group type code in block B - response 6 contains group type*/
            uint16 group_type=(pRx_rds[BLKB_INDEX]>>3);

            FM_DEBUG(("NEW BLK B received\n"));
            FM_DEBUG(("program_type decoded %d \n",program_type));

            FM_ASSERT(pGlobal_rds->program_service);
            FM_ASSERT(pGlobal_rds->radio_text);

            if (pGlobal_rds->program_type!=program_type) /*Program type changed*/
            {
                pGlobal_rds->program_type=program_type;

                /*Range check for program type*/
                if (program_type>=0 && program_type< MAX_NUM_PROGRAM_TYPE)
                {                    
                    /*Send to main app for display*/
                    MAKE_FM_MESSAGE_WITH_LEN(FM_PLUGIN_RDS_IND, MAX_PROGRAM_TYPE+1);
                    message->rds_type=FMRX_RDS_PROGRAM_TYPE;
                    message->data_len=MAX_PROGRAM_TYPE+1;
                    memcpy(message->data, (uint8*)pProgramType[program_type], MAX_PROGRAM_TYPE+1);
                    FM_DEBUG(("RT data sent to Headset app %s \n", message->data));
                    MessageSend(fm_rx_data->app_task, FM_PLUGIN_RDS_IND, message);
                }
            }

            if (((group_type==RDS_GROUPTYPE_0A) ||(group_type==RDS_GROUPTYPE_0B))/*program service data*/
                && ((bler&RDS_BLER_BLKD_MASK)!=RDS_BLER_UNCORRECTABLE))
            {
                fm_rx_decode_program_service(pRx_rds, pGlobal_rds);
            }
            else if ((group_type==RDS_GROUPTYPE_2A) || (group_type==RDS_GROUPTYPE_2B)) /*radio text data*/
            {
                fm_rx_decode_radio_text(pRx_rds, pGlobal_rds);                
            }
            else
            {
                FM_DEBUG(("Ind ignored for group type: %d bler 0x%x \n", group_type, bler));
            }
        }
        else
        {
            FM_DEBUG(("New block may not have been received\n"));
        }
    }
    else
    {
        FM_DEBUG(("Block ignored \n"));
    }
}


/****************************************************************************
NAME 
    fm_rx_check_rds_status
    
DESCRIPTION
    function to check whether the FM receiver chip has successfully received RDS information
    this function checks the interrupt status bit for RDS    
    
RETURNS
    void
*/ 
static void fm_rx_check_rds_status(void)
{
    uint8 cmd[2];
    uint16 ack = 0;

    /*It is possible that even after a power down, status for a previous request may come*/
    /*Check for null pointer*/
    if (fm_rx_data==NULL)
        return;

    /* check the TUNE COMPLETE interrupt status bit */
    cmd[0] = FMRX_GET_INT_STATUS;
    memset(fm_rx_data->rx_buff, 0, FMRX_MAX_BUFFER_SIZE);

    ack = I2cTransfer(FM_RX_IIC_ADDRESS , cmd, 1, fm_rx_data->rx_buff, 1);
    FM_DEBUG(("RDS: ack %d value 0x%x \n", ack, fm_rx_data->rx_buff[0]));
    
    /* check the RDS interrupt status bit */
    if(fm_rx_data->rx_buff[0] & 0x04) /*RDSINT high*/
    {
        cmd[0] = FMRX_FM_RDS_STATUS;
        cmd[1] = 0x01; /*INTACK - RDS Interrupt Clear. */
 
        /* the RDS received interrupt bit is set, now check the RDS information */
        ack = I2cTransfer(FM_RX_IIC_ADDRESS , cmd, 2, fm_rx_data->rx_buff, FMRX_MAX_RDS_BUFF_SIZE);
        FM_DEBUG(("RDS info received %d \n", ack));

#ifdef DEBUG_FM
    {
        uint8 count;
        for(count=0; count < FMRX_MAX_RDS_BUFF_SIZE; count++)
        {
            FM_DEBUG(("RDS Byte:%d  Value:0x%x \n", count, fm_rx_data->rx_buff[count]));
        }
    }
#endif

        /*Decode the received RDS info-Contains single group as FIFO  count=1*/
        fm_rx_decode_rds(fm_rx_data->rx_buff, &fm_rx_data->rds_data);       
        /*Get the next RDS data */
        MessageSendLater (gFmRxPlugInTask, FMRX_RDS_STATUS_MSG, NULL, FM_COMMAND_CTS_DELAY);

    }
    
    /* RDS read not yet completed, reschedule another check in some time */
    else
    {
           MessageSendLater (gFmRxPlugInTask, FMRX_RDS_STATUS_MSG, NULL, FM_RDS_INITIAL_DELAY);
    }
}

/*************************************************************************
NAME
    fm_rx_init_set_property
    
DESCRIPTION
    Set next initialisation property to the FM RX
*/
static void fm_rx_init_set_property(void)
{
    FM_ASSERT(fm_rx_data);
    
    if ((fm_rx_data->parameter_value == NULL) && (fm_rx_data->parameter_id == NULL))
    {
        fm_rx_data->parameter_value = &fm_rx_data->config.seek_band_bottom;
        fm_rx_data->parameter_id = fm_rx_opcode;
        fm_rx_data->state = FMRX_STATE_INITIALIZING;
    }

    /* when all the configuration parameters have been set, send an ind msg to the vm app */
    if ((*fm_rx_data->parameter_id) == FMRX_END)
    {
        MAKE_FM_MESSAGE(FM_PLUGIN_INIT_IND);

        FM_DEBUG(("fm_rx_init_set_property: init done\n"));
        fm_rx_data->state = FMRX_STATE_READY;

        fm_rx_data->parameter_id=NULL;
        fm_rx_data->parameter_value=NULL;
        
        message->result = TRUE;
        MessageSend(fm_rx_data->app_task, FM_PLUGIN_INIT_IND, message);
    }    
    else
    {
        if (fm_rx_write_prop((*fm_rx_data->parameter_id), (*fm_rx_data->parameter_value)))
        {
            ++fm_rx_data->parameter_id;            
            ++fm_rx_data->parameter_value;
            MessageSendLater(gFmRxPlugInTask, FMRX_INIT_PROPERTY_MSG, NULL, FM_COMMAND_CTS_DELAY);
        }
        else
        {
            MAKE_FM_MESSAGE(FM_PLUGIN_INIT_IND);

            FM_DEBUG(("fm_rx_init_set_property: init fail\n"));
            fm_rx_data->state = FMRX_STATE_IDLE;

            message->result = FALSE;
            MessageSend(fm_rx_data->app_task, FM_PLUGIN_INIT_IND, message);
        }
    }
}


/*************************************************************************
NAME
    fm_rx_init
    
DESCRIPTION
    Allocate and initialise FM RX control structure
    Send data to initialise FM chip after setup time
*/
static void fm_rx_init(FM_PLUGIN_INIT_MSG_T *msg)
{
    /* obtain pointer to malloc'd memory which already has pskey configuration loaded */    
    fm_rx_data = msg->fm_data;

    /* initialise the data structure */
    fm_rx_data->app_task = msg->app_task;
    fm_rx_data->state = FMRX_STATE_IDLE;
    fm_rx_data->currently_tuned_freq = FMRX_INVALID_FREQ;
    fm_rx_data->volume = FMRX_DEFAULT_VOLUME;
    fm_rx_alloc_rds_buff();
    fm_rx_init_rds();

    /* reset the FM chip and continue initialisation */        
    MessageSendLater(gFmRxPlugInTask, FMRX_RESET_LOW_MSG, NULL, 0);
}      
        
        
/*************************************************************************
NAME
    fm_rx_tune
    
DESCRIPTION
    Send command to FM receiver chip to tune to the passed in frequency

RETURNS
    whether command was sent or not
*/
static bool fm_rx_tune(uint16 freq)
{
    uint8 fm_data[FMRX_TUNE_LEN];
    FM_DEBUG(("fm_rx_tune 0x%x\n", freq));
    
    fm_data[0] = FMRX_FM_TUNE_FREQ;
    fm_data[1]=  0x00; 
    fm_data[2] = HIGHBYTE(freq);
    fm_data[3] = LOWBYTE(freq);
    fm_data[4]=  0x00;
    return (fm_rx_write_command(fm_data, FMRX_TUNE_LEN));
}

/*************************************************************************
NAME
    fm_rx_rx_seek
    
DESCRIPTION
    function to start auto tuning (seek) is the direction specifed by passed in param

RETURNS
    whether the command to autotune was sent ok
*/
static bool fm_rx_seek(fm_rx_tune_state UpDn)
{
    uint8 fm_data[FMRX_SEEK_LEN];

    if (UpDn==FMRX_SEEKUP)
    {
        FM_DEBUG(("fm_rx_seek_up\n"));
        fm_data[0] = FMRX_FM_SEEK_START;
        fm_data[1]=  FMRX_SEEK_UP_AND_WRAP; 
    }
    else
    {        
        FM_DEBUG(("fm_rx_seek_down\n"));
        fm_data[0] = FMRX_FM_SEEK_START;
        fm_data[1]=  FMRX_SEEK_DOWN_AND_WRAP;
    }
    
    return (fm_rx_write_command(fm_data, FMRX_SEEK_LEN));
}

/*************************************************************************
NAME
    fm_rx_handle_tune_req
    
DESCRIPTION
    issues an auto tune (seek) in the direction specified and checks if successfully
    initiated, if so it schedules a tune status check 120mS in the future which will
    determine if it managed to tune to a station, if auto tune failed to start then
    a negative ind is sent to the VM app

RETURNS
    none
*/
static void fm_rx_handle_tune_req(fm_rx_tune_state TuneUpDn)
{
    FM_ASSERT(fm_rx_data);
    FM_DEBUG(("FM RX State %d\n", fm_rx_data->state));

    /* initiated an Auto Tune in the direction specified, checking it started ok */
    if ((fm_rx_data->state==FMRX_STATE_READY) && (fm_rx_seek(TuneUpDn)))
    {       
        /* auto tune started, check the tune status in 120mS time */
        MessageSendLater(gFmRxPlugInTask, FMRX_TUNE_STATUS_MSG, NULL, FM_TUNE_CTS_DELAY);
    }
    /* auto tune couldn't start for whatever reason */
    else
    {
        MAKE_FM_MESSAGE(FM_PLUGIN_TUNE_COMPLETE_IND);
        message->result = FALSE;
        message->tuned_freq=FMRX_INVALID_FREQ;
        MessageSend(fm_rx_data->app_task, FM_PLUGIN_TUNE_COMPLETE_IND, message);
    }
}

/*************************************************************************
NAME
    message_handler
    
DESCRIPTION
    Handle internal and FM library messages
*/
static void message_handler (Task task, MessageId id, Message message)
{
    FM_DEBUG(("FM RX: msg %04X\n", id));

    switch (id)
    {
        /***********Internal messages***********/
        
        /* drive reset line low on FM receiver chip*/
        case FMRX_RESET_LOW_MSG:
            FM_DEBUG(("FMRX_RESET_LOW_MSG\n"));
            fm_rx_reset_low();
            MessageSendLater (gFmRxPlugInTask, FMRX_RESET_HIGH_MSG, NULL, FM_RESET_DELAY);/*reset > 150m*/
            break;        

        /* drive reset line high on FM receiver chip*/
        case FMRX_RESET_HIGH_MSG:
            FM_DEBUG(("FMRX_RESET_HIGH_MSG\n"));
            fm_rx_reset_high();
            MessageSendLater (gFmRxPlugInTask, FMRX_POWER_UP_MSG, NULL, FM_COMMAND_CTS_DELAY);
            break;

        /* Power Up receiver chip and set required operating properties */
        case FMRX_POWER_UP_MSG:
            FM_DEBUG(("FMRX_POWER_UP_MSG\n"));
            fm_rx_power_up();
            fm_rx_data->parameter_id = NULL;
            fm_rx_data->parameter_value = NULL;
            MessageSendLater(gFmRxPlugInTask, FMRX_INIT_PROPERTY_MSG, NULL, FM_POWER_UP_CTS_DELAY);
            break;
            
        /* obtain the hardware and software versions */
        case FMRX_GET_REV_MSG:
            FM_DEBUG(("FMRX_GET_REV_MSG\n"));
            fm_rx_get_rev();
            break;            

        /* set a configuration property */    
        case FMRX_INIT_PROPERTY_MSG:
            FM_DEBUG(("FMRX_INIT_PROPERTY_MSG\n"));
            fm_rx_init_set_property();
            break;        
        
        /* obtain the FM tune status */    
        case FMRX_TUNE_STATUS_MSG:
            FM_DEBUG(("FMRX_TUNE_STATUS_MSG\n"));          

            /*Check tune status*/
            fm_rx_check_tune_status();
            break;

        /* configure the output audio format of the FM reciever chip */
        case FMRX_SET_OUTPUT_FORMAT_MSG:
            fm_rx_write_prop(DIGITAL_OUTPUT_FORMAT, 0x0000);
            MessageSendLater(gFmRxPlugInTask, FMRX_SET_SAMPLE_RATE_MSG, NULL, FM_COMMAND_CTS_DELAY);
            break;
            
        /* configure the audio sample rate of the FM audio */
        case FMRX_SET_SAMPLE_RATE_MSG:
            fm_rx_write_prop(DIGITAL_OUTPUT_SAMPLE_RATE, FM_DIGITAL_SAMPLE_RATE);/*FM to work with fixed sample rate 48Khz*/
            /*End of tuning sequence, can wait for tune_status now*/
            MessageSendLater(gFmRxPlugInTask, FMRX_TUNE_STATUS_MSG, NULL, FM_TUNE_CTS_DELAY);
            break;

        /* Initiate RDS */    
        case FMRX_RDS_INITIATE_MSG:
            FM_DEBUG(("FMRX_RDS_INITIATE_MSG\n"));
            fm_rx_data->rds_data.program_code_valid=FALSE;

            fm_rx_write_prop(FM_RDS_INT_SOURCE, 0x0001);
            
            /*Cancel RDS after trying for some time as the station may not be supporting it*/
            MessageSendLater(gFmRxPlugInTask, FMRX_RDS_CANCEL_MSG, NULL, FM_RDS_TIMEOUT);

            MessageSendLater(gFmRxPlugInTask, FMRX_RDS_SET_FIFO_MSG, NULL, FM_COMMAND_CTS_DELAY);            
            break;

        /*Set RDS FIFO Count*/
        case FMRX_RDS_SET_FIFO_MSG:
            FM_DEBUG(("FMRX_RDS_SET_FIFO_MSG\n"));
            fm_rx_write_prop(FM_RDS_INT_FIFO_COUNT, 0x0001);
            MessageSendLater(gFmRxPlugInTask, FMRX_RDS_SET_CONFIG_MSG, NULL, FM_COMMAND_CTS_DELAY);
            break;

        /*RDS config to set block error rates*/
        case FMRX_RDS_SET_CONFIG_MSG:
            FM_DEBUG(("FMRX_RDS_SET_CONFIG_MSG\n"));
            fm_rx_write_prop(FM_RDS_CONFIG, 0xaa01);
            /*End of RDS sequence, can wait for rds_status now*/
            MessageSendLater(gFmRxPlugInTask, FMRX_RDS_STATUS_MSG, NULL, FM_COMMAND_CTS_DELAY);
            break;

        /* obtain the RDS status */    
        case FMRX_RDS_STATUS_MSG:
            FM_DEBUG(("FMRX_RDS_STATUS_MSG\n"));
            fm_rx_check_rds_status();
            break;

        /* cancel RDS if a radio station does not support it */
        case FMRX_RDS_CANCEL_MSG:
            FM_DEBUG(("FMRX_RDS_CANCEL_MSG\n"));
            /*This message cancels the rds request for a station not supporting RDS after trying for sometime*/
            MessageCancelAll(gFmRxPlugInTask, FMRX_RDS_STATUS_MSG);
            break;

        /**********External messages**********/
        
        /* initialise the FM chip and tune to stored default frequency */    
        case FM_PLUGIN_INIT_MSG:
            FM_DEBUG(("FM_PLUGIN_INIT_MSG\n"));
            fm_rx_init((FM_PLUGIN_INIT_MSG_T*) message);
            break;
           
        /* tune to frequency that FM was last tuned to */    
        case FMRX_TUNE_FREQ_MSG:
            /* get the frequency to tune to */
            fm_rx_data->currently_tuned_freq = (((FMRX_TUNE_FREQ_MSG_T*) message)->frequency);
            /* check whether a valid frequency has been passed in */
            if ((fm_rx_data->currently_tuned_freq >= fm_rx_data->config.seek_band_bottom)&&
                (fm_rx_data->currently_tuned_freq <= fm_rx_data->config.seek_band_top))
            {
                /*FM_TUNE_FREQ command must be sent after the POWER_UP command to start the internal clocking*/
                fm_rx_tune(fm_rx_data->currently_tuned_freq);
            }
            else
            {
                /*FM_TUNE_FREQ command must be sent after the POWER_UP command to start the internal clocking,
                  no frequency available so tune to lowest frequency to start hardware */
                fm_rx_tune(fm_rx_data->config.seek_band_bottom);               
            }
            /* set the output rate of the I2S interface */
            MessageSendLater(gFmRxPlugInTask, FMRX_SET_OUTPUT_FORMAT_MSG, NULL, FM_COMMAND_CTS_DELAY);
            break;

        /* start auto tuning in an upwards direction */
        case FM_PLUGIN_RX_TUNE_UP_MSG:
            FM_DEBUG(("FM_PLUGIN_RX_TUNE_UP_MSG\n"));

            /*Cancel previous tune status requests*/
            MessageCancelAll(gFmRxPlugInTask, FMRX_TUNE_STATUS_MSG);

            fm_rx_handle_tune_req(FMRX_SEEKUP);
            break;

        /* start auto tuning in an downwards direction */
        case FM_PLUGIN_RX_TUNE_DOWN_MSG:
            FM_DEBUG(("FM_PLUGIN_RX_TUNE_DOWN_MSG\n"));

            /*Cancel previous tune status requests*/
            MessageCancelAll(gFmRxPlugInTask, FMRX_TUNE_STATUS_MSG);

            fm_rx_handle_tune_req(FMRX_SEEKDOWN);
            break;
         
        /* power down the FM hardware and free allocated memory slot */    
        case FM_PLUGIN_RX_POWER_OFF_MSG:
            FM_DEBUG(("FM_PLUGIN_RX_POWER_OFF_MSG\n"));
            /*Cancel previous tune status requests*/
            MessageCancelAll(gFmRxPlugInTask, FMRX_TUNE_STATUS_MSG);

            MessageCancelAll(gFmRxPlugInTask, FMRX_RDS_STATUS_MSG);
            MessageCancelAll(gFmRxPlugInTask, FMRX_RDS_INITIATE_MSG);
            MessageCancelAll(gFmRxPlugInTask, FMRX_RDS_CANCEL_MSG);
            fm_rx_power_down();

            break;
            
        /* configure the FM reciever chip volume */    
        case FM_PLUGIN_RX_UPDATE_VOLUME_MSG:
            FM_DEBUG(("FM_PLUGIN_RX_UPDATE_VOLUME_MSG\n"));
            fm_rx_update_volume((FM_PLUGIN_RX_UPDATE_VOLUME_MSG_T*) message);
            break;
            
        default:
            break;

    }
}





