/* Copyright (C) Cambridge Silicon Radio Limited 2011-2014 */
/* Part of ADK 3.5 */

#include <bdaddr.h>

void BdaddrConvertTypedBluestackToVm(
        typed_bdaddr            *out, 
        const TYPED_BD_ADDR_T   *in
        )
{
    switch (in->type)
    {
        case TBDADDR_PUBLIC:
            out->type = TYPED_BDADDR_PUBLIC;
            break;
        case TBDADDR_RANDOM:
            out->type = TYPED_BDADDR_RANDOM;
            break;
        default:
            out->type = TYPED_BDADDR_INVALID;
            break;
    }
    BdaddrConvertBluestackToVm(&out->addr, &in->addr);
}
