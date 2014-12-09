/****************************************************************************
Copyright (C) Cambridge Silicon Radio Ltd. 2004

FILE NAME
    hfp_service_record.h
    
DESCRIPTION
    
*/

#ifndef HFP_SERVICE_RECORD_H_
#define HFP_SERVICE_RECORD_H_


static const uint8 hfp_service_record[] =
{
    /* Service class ID list */
    0x09,0x00,0x01, /* AttrID , ServiceClassIDList */
    0x35,0x06, /* 6 bytes in total DataElSeq */
    0x19,0x11,0x1e,/* 2 byte UUID, Service class = HF */
    0x19,0x12,0x03,/* 2 byte UUID Service class = GenericAudio */
        
    /* protocol descriptor list */
    0x09,0x00,0x04,/* AttrId ProtocolDescriptorList */
    0x35,0x0c, /* 11 bytes in total DataElSeq */
    0x35,0x03, /*3 bytes in DataElSeq */
    0x19, 0x01,0x00,/* 2 byte UUID, Protocol = L2CAP */
        
    0x35,0x05, /* 5 bytes in DataElSeq */
    0x19, 0x00,0x03,  /* 1 byte UUID Protocol = RFCOMM */
    0x08, 0x00, /* 1 byte UINT - server channel template value 0 - to be filled in by app */

    /* Language base list */
    0x09, 0x00, 0x06, /* AttrId LanguageBaseAttributeIDList */
    0x35, 0x09,  /* 9 bytes in total DataElSeq */
    0x09, 0x65, 0x6e,  /* 2 byte UINT, Natural language = en (english) */
    0x09, 0x00, 0x6a,  /* 2 byte UINT, Character encoding = UTF-8 */
    0x09, 0x01, 0x00,  /* 2 byte UINT, Base attr id = 0x100 */

    /* profile descriptor list */
    0x09,0x00,0x09, /* AttrId, ProfileDescriptorList */
    0x35,0x08, /* 8 bytes in total DataElSeq */
    0x35,0x06, /* 6 bytes in total DataElSeq */
    0x19, 0x11,0x1e, /* 2 byte UUID, Service class = HF */

    0x09, 0x00,0x00,  /* 2 byte UINT, version = 0x00 - to be filled in. */

    /* service name */
    0x09, 0x01, 0x00, /* AttrId - Service Name */
    0x25, 0x0F, /* 15 byte string */
    'H','a','n','d','s','-','F', 'r', 'e', 'e', ' ', 'u', 'n', 'i', 't',
        
    /* Supported features - passed in from the application */    
    0x09, 0x03, 0x11,   /* AttrId - Supported Features */
    0x09, 0x00, 0x00    /* 2 byte UINT - supported features inserted by app */
                        /* EC and/or NR fn          - 0 (LSB) */
                        /* 3 way calls              - 0 */
                        /* CLI presentation         - 0 */
                        /* Voice recognition fn     - 0 */
                        /* Remote volume control    - 0 */
                        /* Wide-band Speech            - 0 */
};


/* 
Indexes of values we need to insert. Update these if you change the 
service record above.
*/
#define HFP_RFCOMM_IDX          27
#define HFP_VERSION_MSB_IDX     53
#define HFP_VERSION_LSB_IDX     54
#define HFP_FEATURES_MSB_IDX    79
#define HFP_FEATURES_LSB_IDX    80


#endif /* HFP_SERVICE_RECORD_H_ */

