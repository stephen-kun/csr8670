/* Copyright (C) Cambridge Silicon Radio Limited 2010-2014 */
/* Part of ADK 3.5 

FILE NAME
	spp_sdp.c        

DESCRIPTION
	Functions used storing the SPP sdp_handler state.

*/

#include "spps_private.h"

static uint32 spp_sdp_service_handle = 0;

void sppStoreServiceHandle(uint32 service_handle)
{
    spp_sdp_service_handle = service_handle;
}

uint32 sppGetServiceHandle(void)
{
    return spp_sdp_service_handle;
}


