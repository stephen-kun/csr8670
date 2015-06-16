/* Copyright (C) Cambridge Silicon Radio Limited 2011-2014 */
/* Part of ADK 3.5 */

#include <bdaddr.h>

void BdaddrConvertBluestackToVm(bdaddr *out, const BD_ADDR_T *in)
{
    out->lap = (uint32)(in->lap);
    out->uap = (uint8)(in->uap);
    out->nap = (uint16)(in->nap);
}
