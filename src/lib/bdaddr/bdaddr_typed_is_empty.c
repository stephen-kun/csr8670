/* Copyright (C) Cambridge Silicon Radio Limited 2005-2014 */
/* Part of ADK 3.5 */

#include <bdaddr.h>

bool BdaddrTypedIsEmpty(const typed_bdaddr *in)
{
    return  in->type == TYPED_BDADDR_INVALID &&
            BdaddrIsZero(&in->addr);
}
