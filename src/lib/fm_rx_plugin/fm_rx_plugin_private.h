/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2012

FILE NAME
    FM_RX_PLUGIN_PRIVATE.h
    
DESCRIPTION
    Defines FM RX commands and properties
    
*/
#ifndef FM_RX_PLUGIN_PRIVATE_H
#define FM_RX_PLUGIN_PRIVATE_H

#ifndef NULL
#define NULL ((void *) 0)
#endif

#include <panic.h>

#ifdef DEBUG_FM
    #include <stdio.h>
    #define FM_DEBUG(x) {printf x;}
    #define FM_PANIC() { Panic(); }
    #define FM_ASSERT(x) { if (!(x)) { Panic(); } }
#else
    #define FM_DEBUG(x)
    #define FM_PANIC() { Panic(); }
    #define FM_ASSERT(x) 
#endif   


/*FM RX Command Values*/
#define FMRX_SEEK_UP_AND_WRAP (0x0C)
#define FMRX_SEEK_DOWN_AND_WRAP (0x04)
#define FM_RX_UNMUTE (0x0000)
#define FM_RX_MUTE (0x0002)
#define FM_EMBEDDED_ANTENNA (0x0001)
#define FM_DIGITAL_SAMPLE_RATE (0xBB80)

/*FM RX Command Lengths*/
#define FMRX_POWER_UP_LEN (0x03)
#define FMRX_GET_REV_LEN (0x0F)
#define FMRX_SEEK_LEN (0x02)
#define FMRX_TUNE_LEN (0x05)

/* FM RX Commands */
#define FMRX_POWER_UP (0x01)     /*Power up device and mode selection.*/
#define FMRX_GET_REV (0x10)      /* Returns revision information on the device.*/
#define FMRX_POWER_DOWN (0x11)   /*Power down device.*/
#define FMRX_SET_PROPERTY (0x12) /*Sets the value of a property.*/
#define FMRX_GET_PROPERTY (0x13) /*Retrieves a property’s value.*/
#define FMRX_GET_INT_STATUS (0x14) /*Reads interrupt status bits.*/
#define FMRX_PATCH_ARGS (0x15)     /*Reserved command used for patch file downloads.*/
#define FMRX_PATCH_DATA (0x16)     /*Reserved command used for patch file downloads.*/
#define FMRX_FM_TUNE_FREQ (0x20)   /*Selects the FM tuning frequency.*/
#define FMRX_FM_SEEK_START (0x21)  /*Begins searching for a valid frequency.*/
#define FMRX_FM_TUNE_STATUS (0x22) /*Queries the status of previous FM_TUNE_FREQ or FM_SEEK_START command.*/
#define FMRX_FM_RSQ_STATUS (0x23)
#define FMRX_FM_RDS_STATUS (0x24)
#define FMRX_FM_AGC_STATUS (0x27)
#define FMRX_FM_AGC_OVERRIDE (0x28)
#define FMRX_GPIO_CTL (0x80)
#define FMRX_GPIO_SET (0x81)



/* FM RX properties */
#define GPO_IEN                                  (0x0001)
#define DIGITAL_OUTPUT_FORMAT                    (0x0102)
#define DIGITAL_OUTPUT_SAMPLE_RATE               (0x0104)
#define REFCLK_FREQ                              (0x0201)
#define REFCLK_PRESCALE                          (0x0202)
#define FM_DEEMPHASIS                            (0x1100)
#define FM_CHANNEL_FILTER                        (0x1102)
#define FM_BLEND_STEREO_THRESHOLD                (0x1105)
#define FM_BLEND_MONO_THRESHOLD                  (0x1106)
#define FM_ANTENNA_INPUT                         (0x1107)
#define FM_MAX_TUNE_ERROR                        (0x1108)
#define FM_RSQ_INT_SOURCE                        (0x1200)
#define FM_RSQ_SNR_HI_THRESHOLD                  (0x1201)
#define FM_RSQ_SNR_LO_THRESHOLD                  (0x1202)
#define FM_RSQ_RSSI_HI_THRESHOLD                 (0x1203)
#define FM_RSQ_RSSI_LO_THRESHOLD                 (0x1204)
#define FM_RSQ_MULTIPATH_HI_THRESHOLD            (0x1205)
#define FM_RSQ_MULTIPATH_LO_THRESHOLD            (0x1206)
#define FM_RSQ_BLEND_THRESHOLD                   (0x1207)
#define FM_SOFT_MUTE_RATE                        (0x1300)
#define FM_SOFT_MUTE_SLOPE                       (0x1301)
#define FM_SOFT_MUTE_MAX_ATTENUATION             (0x1302)
#define FM_SOFT_MUTE_SNR_THRESHOLD               (0x1303)
#define FM_SOFT_MUTE_RELEASE_RATE                (0x1304)
#define FM_SOFT_MUTE_ATTACK_RATE                 (0x1305)
#define FM_SEEK_BAND_BOTTOM                      (0x1400)
#define FM_SEEK_BAND_TOP                         (0x1401)
#define FM_SEEK_FREQ_SPACING                     (0x1402)
#define FM_SEEK_TUNE_SNR_THRESHOLD               (0x1403)
#define FM_SEEK_TUNE_RSSI_THRESHOLD              (0x1404)
#define FM_RDS_INT_SOURCE                        (0x1500)
#define FM_RDS_INT_FIFO_COUNT                    (0x1501)
#define FM_RDS_CONFIG                            (0x1502)
#define FM_RDS_CONFIDENCE                        (0x1503)
#define FM_AGC_ATTACK_RATE                       (0x1700)
#define FM_AGC_RELEASE_RATE                      (0x1701)
#define FM_BLEND_RSSI_STEREO_THRESHOLD           (0x1800)
#define FM_BLEND_RSSI_MONO_THRESHOLD             (0x1801)
#define FM_BLEND_RSSI_ATTACK_RATE                (0x1802)
#define FM_BLEND_RSSI_RELEASE_RATE               (0x1803)
#define FM_BLEND_SNR_STEREO_THRESHOLD            (0x1804)
#define FM_BLEND_SNR_MONO_THRESHOLD              (0x1805)
#define FM_BLEND_SNR_ATTACK_RATE                 (0x1806)
#define FM_BLEND_SNR_RELEASE_RATE                (0x1807)
#define FM_BLEND_MULTIPATH_STEREO_THRESHOLD      (0x1808)
#define FM_BLEND_MULTIPATH_MONO_THRESHOLD        (0x1809)
#define FM_BLEND_MULTIPATH_ATTACK_RATE           (0x180A)
#define FM_BLEND_MULTIPATH_RELEASE_RATE          (0x180B)
#define FM_BLEND_MAX_STEREO_SEPARATION           (0x180C)
#define FM_NB_DETECT_THRESHOLD                   (0x1900)
#define FM_NB_INTERVAL                           (0x1901)
#define FM_NB_RATE                               (0x1902)
#define FM_NB_IIR_FILTER                         (0x1903)
#define FM_NB_DELAY                              (0x1904)
#define FM_HICUT_SNR_HIGH_THRESHOLD              (0x1A00)
#define FM_HICUT_SNR_LOW_THRESHOLD               (0x1A01)
#define FM_HICUT_ATTACK_RATE                     (0x1A02)
#define FM_HICUT_RELEASE_RATE                    (0x1A03)
#define FM_HICUT_MULTIPATH_TRIGGER_THRESHOLD     (0x1A04)
#define FM_HICUT_MULTIPATH_END_THRESHOLD         (0x1A05)
#define FM_HICUT_CUTOFF_FREQUENCY                (0x1A06)
#define RX_VOLUME                                (0x4000)
#define RX_HARD_MUTE                             (0x4001)
#define FMRX_END                                 (0xFFFF)


/*Programmer defines, PS key defines etc*/
#define FMRX_PSKEY_USR_CONFIG (43)
#define FMRX_INVALID_FREQ (0x0000) /*value also used to write to ps key */
#define FMRX_DEFAULT_FREQ (9430)
#define FM_RX_IIC_ADDRESS ((0x11) << 1)

/*Timing*/

/*Clear-To-Send CTS bit is managed using tested delay, 
although can also be done by checking the CTS bit by 
sending FMRX_GET_INT_STATUS command as in fm_rx_check_int_status*/

#define FM_RESET_DELAY  200 /*ms*/
#define FM_POWER_UP_CTS_DELAY  110 /*ms*/
#define FM_COMMAND_CTS_DELAY 60 /*ms*/
#define FM_TUNE_CTS_DELAY  120 /*ms*/
#define FM_RDS_INITIAL_DELAY 120 /*Initial delay to get RDS data, once we start receiving RDS can reduce the delay*/

/* Set property macro */
#define LOWBYTE(v)   ((unsigned char) (v & 0x00FF))
#define HIGHBYTE(v)  ((unsigned char) (((unsigned int) (v)) >> 8))
#define FMSETPROP(c,p)  {c[0]=FMRX_SET_PROPERTY;c[1]=0x00; c[2] = HIGHBYTE(p);c[3] = LOWBYTE(p);}
#define FMGETPROP(c,p)  {c[0]=FMRX_GET_PROPERTY;c[1]=0x00; c[2] = HIGHBYTE(p);c[3] = LOWBYTE(p);}
#define mFM_SET_CONFIG(psdata, globaldata, defaultdata){ (psdata!=0x0000) ? (globaldata=psdata):(globaldata=defaultdata);}


/* When rds is requested a time out has to be defined if no valid RDS
   data has been received in a given time. The RDS recomendation to radio stations
   is to transmit PS name every 1 sec, but often a higher repeat cycle is used.*/
#define FM_RDS_TIMEOUT  D_SEC(50) 


/*!
  @brief FM RX RDS group types
*/
typedef enum 
{
    RDS_GROUPTYPE_0A,  /*contains program service name for group A*/
    RDS_GROUPTYPE_0B,  /*contains program service name for group B*/
    RDS_GROUPTYPE_1A,  /*contains program item number for group A*/
    RDS_GROUPTYPE_1B,  /*contains program item number for group B*/
    RDS_GROUPTYPE_2A,  /*contains program radio text for group A*/
    RDS_GROUPTYPE_2B   /*contains program radio text for group B*/
    
}FM_RDS_GroupType;

#define RDS_BLER_UNCORRECTABLE 0x03 /*Block error rate*/
#define RDS_BLER_NO_ERROR 0 /*Block error rate*/

#define RDS_BLER_BLKA_MASK 0xC0
#define RDS_BLER_BLKB_MASK 0x30
#define RDS_BLER_BLKC_MASK 0x0C
#define RDS_BLER_BLKD_MASK 0x03

#define RDSNEWBLOCKA_MASK (0x10)
#define RDSNEWBLOCKB_MASK (0x20)

#define MAX_NUM_PROGRAM_TYPE (16) /*Can be max 32*/

/*Max number of bytes supported for each RDS type*/
#define MAX_PROGRAM_TYPE 16
#define MAX_PROGRAM_SERVICE 8
#define MAX_RADIO_TEXT 64


#define BLKA_INDEX 4   /*Resp byte 4 and 5*/ 
#define BLKB_INDEX 6   /*Resp byte 6 and 7*/ 
#define BLKC_INDEX 8   /*Resp byte 8 and 9*/ 
#define BLKD_INDEX 10   /*Resp byte 10 and 11*/


#define PROGRAM_TYPE_MASK1                       (0x03)
#define PROGRAM_TYPE_OFFSET1                     (0x03)
#define PROGRAM_TYPE_MASK2                       (0xE0)
#define PROGRAM_TYPE_OFFSET2                     (0x05)
#define PS_ADDR_MASK                          (0x03)
#define PS_ADDR_OFFSET 2 /*Address offset for program service*/
#define RT_ADDR_OFFSET 4 /*Address offset for radio text*/
#define RT_ADDR_MASK                          (0x0F)
#define GROUP_VARIANT_MASK                       (0x08)

/*!
  @brief FM RX set property message data struture containing the property Id and value
*/

typedef struct
{
    uint16 prop;
    uint16 value;
} FMRX_SET_PROPERTY_MSG_T;

/*!
  @brief Tune state for FM RX 
*/

typedef enum
{
    FMRX_SEEKDOWN,
    FMRX_SEEKUP
    
} fm_rx_tune_state;

/*!
  @brief FM RX internal messages
*/
typedef enum
{
    FMRX_RESET_LOW_MSG =1,
    FMRX_RESET_HIGH_MSG,
    FMRX_POWER_UP_MSG,
    FMRX_GET_REV_MSG,
    FMRX_INIT_PROPERTY_MSG,
    FMRX_TUNE_STATUS_MSG,
    FMRX_SET_OUTPUT_FORMAT_MSG,
    FMRX_RDS_INITIATE_MSG,
    FMRX_RDS_SET_FIFO_MSG,
    FMRX_RDS_SET_CONFIG_MSG,
    FMRX_RDS_STATUS_MSG,
    FMRX_RDS_CANCEL_MSG,
    FMRX_SET_SAMPLE_RATE_MSG

} fm_rx_internal_message;


#endif /*FM_RX_PLUGIN_PRIVATE_H*/
