#ifndef _GAP_AD_TYPES_H_
#define _GAP_AD_TYPES_H_

/*
    Advertising data types (see GAP section 11.1)
*/
typedef enum
{
    AD_TYPE_FLAGS                       = 0x01,   /*!< See Advertising Data Flags */
    AD_TYPE_SERVICE_UUID_16BIT          = 0x02,
    AD_TYPE_SERVICE_UUID_16BIT_LIST     = 0x03,
    AD_TYPE_SERVICE_UUID_32BIT          = 0x04,
    AD_TYPE_SERVICE_UUID_32BIT_LIST     = 0x05,
    AD_TYPE_SERVICE_UUID_128BIT         = 0x06,
    AD_TYPE_SERVICE_UUID_128BIT_LIST    = 0x07,
    AD_TYPE_LOCAL_NAME_SHORT            = 0x08,
    AD_TYPE_LOCAL_NAME_COMPLETE         = 0x09,
    AD_TYPE_TX_POWER                    = 0x0A,
    
    AD_TYPE_OOB_DEVICE_CLASS            = 0x0D,
    AD_TYPE_OOB_SSP_HASH                = 0x0E,
    AD_TYPE_OOB_SSP_RANDOM              = 0x0F,
    AD_TYPE_SM_TK                       = 0x10,
    AD_TYPE_SM_FLAGS                    = 0x11,   /*!< See Security Manager Flags */
    AD_TYPE_SLAVE_CONN_INTERVAL         = 0x12,
    AD_TYPE_SIGNED_DATA                 = 0x13,
    AD_TYPE_SERVICE_SOLICIT_UUID_16BIT  = 0x14,
    AD_TYPE_SERVICE_SOLICIT_UUID_128BIT = 0x15,
    AD_TYPE_SERVICE_DATA                = 0x16,
    
    AD_TYPE_MANUF                       = 0xFF

} ad_type_t;


#endif /* _GAP_AD_TYPES_H_ */
