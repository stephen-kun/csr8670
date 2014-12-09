/****************************************************************************
Copyright (C) Cambridge Silicon Radio Limited 2010-2014
Part of ADK 3.5

FILE NAME
    spps_private.h
    
DESCRIPTION
	Header file for the SPP Server profile library containing private members
	
*/

#ifndef SPPS_PRIVATE_H_
#define SPPS_PRIVATE_H_

#include "spps.h"
#include "../spp_common/spp_common_private.h"

/* Default Spp service record */

static const uint8 spp_service_record [] =
{
    0x09, 0x00, 0x01,           /* ServiceClassIDList(0x0001) */
    0x35, 0x03,                 /* DataElSeq 3 bytes */
    0x19, 0x11, 0x01,           /* UUID SerialPort(0x1101) */
    0x09, 0x00, 0x04,           /* ProtocolDescriptorList(0x0004) */
    0x35, 0x0c,                 /* DataElSeq 12 bytes */
    0x35, 0x03,                 /* DataElSeq 3 bytes */
    0x19, 0x01, 0x00,           /* UUID L2CAP(0x0100) */
    0x35, 0x05,                 /* DataElSeq 5 bytes */
    0x19, 0x00, 0x03,           /* UUID RFCOMM(0x0003) */
    0x08, SPP_DEFAULT_CHANNEL,  /* uint8 Suggested RFCOMM channel for SPP */
    0x09, 0x00, 0x06,           /* LanguageBaseAttributeIDList(0x0006) */
    0x35, 0x09,                 /* DataElSeq 9 bytes */
    0x09, 0x65, 0x6e,           /* uint16 0x656e */
    0x09, 0x00, 0x6a,           /* uint16 0x006a */
    0x09, 0x01, 0x00,           /* uint16 0x0100 */
    0x09, 0x01, 0x00,           /* ServiceName(0x0100) = "SPP Dev" */
    0x25, 0x07,                 /* String length 7 */
    'S','P','P',' ','D', 'e', 'v'
};


/* private SPP Server funcitons */
void sppStoreServiceHandle(uint32 service_handle);
uint32 sppGetServiceHandle(void);

#endif /* SPPS_PRIVATE_H_ */
